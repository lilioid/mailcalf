// vim: set filetype=groovy:
library changelog: false, identifier: 'github.com/ftsell/jenkins-pipeline-library@main', retriever: modernSCM([$class: 'GitSCMSource', credentialsId: '', remote: 'https://github.com/ftsell/jenkins-pipeline-library.git', traits: [gitBranchDiscovery()]])

def imageName = "registry.finn-thorben.me/mailserver"
def imageDigest

pipeline {
    agent {
        kubernetes {
          yaml genPodYaml(true, true)
        }
    }
    options {
        skipDefaultCheckout(true)
    }
    triggers {
      pollSCM 'H * * * *'
      cron "H 2 * * * "
    }
    stages {
        stage("Checkout SCM") {
            steps {
                checkout scm
            }
        }
        stage("Create Container Image") {
            steps {
                container("podman") {
                    buildContainer(imageName)
                    script {
                      if (env.BRANCH_IS_PRIMARY == "true") {
                        uploadContainer(imageName, "registry.finn-thorben.me", "registry-credentials")
                      }
                    }
                }
            }
        }
        stage("Deploy") {
            steps {
                container("podman") {
                    script {
                        imageDigest = fetchImageDigest(imageName, "registry.finn-thorben.me", "registry-credentials")
                    }
                }
                container("kustomize") {
                    deployContainer("mailserver", imageName, imageDigest)
                }
            }
        }
    }
}

