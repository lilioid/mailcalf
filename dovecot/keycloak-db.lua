local http_request = require("http.request")
local json = require("json")
local base64 = require("base64")

local KEYCLOAK_URL
local KEYCLOAK_REALM
local KEYCLOAK_CLIENT_ID
local KEYCLOAK_CLIENT_SECRET


--[[
Utility functions and implementation details
--------------------------------------------
]]

--- Do direct auth against keycloak and return an access token (if successful) or nil (if not)
local function do_keycloak_direct_auth(auth_request, username, password)
    -- construct request
    local request = http_request.new_from_uri(KEYCLOAK_URL .. "/auth/realms/" .. KEYCLOAK_REALM .. "/protocol/openid-connect/token")
    request.headers:upsert(":method", "POST")
    request.headers:upsert("Content-Type", "application/x-www-form-urlencoded")
    request.headers:upsert("Accept", "application/json")
    request:set_body("grant_type=password&client_id=" .. KEYCLOAK_CLIENT_ID .. "&client_secret=" .. KEYCLOAK_CLIENT_SECRET .. "&username=" .. username .. "&password=" .. password .. "&scope=profile")

    -- execute
    local response_headers, response = assert(request:go(5))
    auth_request:log_debug("Executed direct auth [user=" .. username .. ", status=" .. response_headers:get(":status") .. "]")

    -- handle response
    if response_headers:get(":status") ~= "200" then
        return nil
    end
    local body = json.decode(assert(response:get_body_as_string()))
    return body.access_token
end

--- Do service account authentication against keycloak and return an access token
local function do_keycloak_sa_auth()
    -- construct request
    local request = http_request.new_from_uri(KEYCLOAK_URL .. "/auth/realms/" .. KEYCLOAK_REALM .. "/protocol/openid-connect/token")
    request.headers:upsert(":method", "POST")
    request.headers:upsert("Content-Type", "application/x-www-form-urlencoded")
    request.headers:upsert("Accept", "application/json")
    request.headers:upsert("Authorization", "Basic " .. base64.encode(KEYCLOAK_CLIENT_ID .. ":" .. KEYCLOAK_CLIENT_SECRET))
    request:set_body("grant_type=client_credentials")

    -- execute
    local response_headers, response = assert(request:go(5))
    dovecot.i_debug("Executed service account auth [status=" .. response_headers:get(":status") .. "]")

    -- handle response
    if response_headers:get(":status") ~= "200" then
        return nil
    end
    local body = json.decode(assert(response:get_body_as_string()))
    return body.access_token
end

--- Do a request to the userinfo endpoint to retrieve and identity token from keycloak. Returns a parsed identity token or nil
local function do_keycloak_userinfo_request(auth_request, access_token)
    -- construct request
    local request = http_request.new_from_uri(KEYCLOAK_URL .. "/auth/realms/" .. KEYCLOAK_REALM .. "/protocol/openid-connect/userinfo")
    request.headers:upsert("Accept", "application/json")
    request.headers:upsert("Authorization", "Bearer " .. access_token)

    -- execute
    local response_headers, response = assert(request:go(5))
    auth_request:log_debug("Executed userinfo request [user=" .. auth_request.user .. ", status=" .. response_headers:get(":status") .. "]")

    -- handle response
    if response_headers:get(":status") ~= "200" then
        return nil
    end
    return json.decode(response:get_body_as_string())
end

--- Do a request to keycloak's admin API to fetch all users
local function do_keycloak_get_users_request(access_token)
    -- construct request
    local request = http_request.new_from_uri(KEYCLOAK_URL .. "/auth/admin/realms/" .. KEYCLOAK_REALM .. "/users")
    request.headers:upsert("Accept", "application/json")
    request.headers:upsert("Authorization", "Bearer " .. access_token)

    -- execute
    local response_headers, response = assert(request:go(5))
    dovecot.i_debug("Executed admin user list request [status=" .. response_headers:get(":status") .. "]")

    -- handle response
    if response_headers:get(":status") ~= "200" then
        return nil
    end
    return json.decode(response:get_body_as_string())
end



--[[
Dovecot API
--------------------------------------
]]

function script_init()
    local conf_file = assert(io.open("/app/conf/keycloak_auth.json", "r"), "config file /app/conf/keycloak_auth.json cannot be read")
    local conf = json.decode(conf_file:read("*a"))
    conf_file:close()

    KEYCLOAK_URL = assert(conf.keycloak_url, "keycloak_url is nil")
    KEYCLOAK_REALM = assert(conf.keycloak_realm, "keycloak_realm is nil")
    KEYCLOAK_CLIENT_ID = assert(conf.keycloak_client_id, "keycloak_client_id")
    KEYCLOAK_CLIENT_SECRET = assert(conf.keycloak_client_secret, "keycloak_client_secret")

    return 0
end

function script_deinit()
end

function auth_passdb_lookup(request)
    local access_token = do_keycloak_direct_auth(request, request.username, request.password)
    if access_token == nil then
        return dovecot.auth.PASSDB_RESULT_PASSWORD_MISMATCH, "could not authenticate"
    end

    local userinfo = do_keycloak_userinfo_request(request, access_token)
    if userinfo == nil then
        return dovecot.auth.PASSDB_RESULT_INTERNAL_FAILURE, "userinfo is nil even though an access token was retrieved"
    end

    return dovecot.auth.PASSDB_RESULT_OK, { password = request.password }
end

function auth_userdb_iterate()
    local access_token = do_keycloak_sa_auth()
    if access_token == nil then
        dovecot.i_warning("Could not get service account access token")
        return {}
    end

    local users = do_keycloak_get_users_request(access_token)
    if users == nil then
        dovecot.i_warning("users is nil even though an access token was retrieved")
        return {}
    end

    local result = {}
    for i, user in ipairs(users) do
        if user ~= nil and user.attributes ~= nil and user.attributes.has_mailbox ~= nil and user.attributes.has_mailbox[1] == "true" then
            result[i] = user.username
        end
    end
    return result
end

function auth_userdb_lookup(request)
    local access_token = do_keycloak_sa_auth()
    if access_token == nil then
        return dovecot.auth.USERDB_RESULT_INTERNAL_FAILURE, "could not get service account access token"
    end

    local users = do_keycloak_get_users_request(access_token)
    if users == nil then
        return dovecot.auth.USERDB_RESULT_INTERNAL_FAILURE, "could not get list of users from keycloak even though an access token was retrieved"
    end

    for _, user in ipairs(users) do
        if user.username == request.username then
            return dovecot.auth.USERDB_RESULT_OK, {}
        end
    end
    return dovecot.auth.USERDB_RESULT_USER_UNKNOWN, nil
end
