# file spam messages into the Junk folder if the X-Spam header is set
require ["fileinto"];

if header :is "X-Spam" "Yes" {
        fileinto "Junk";
}
