provider "google"{
    credentials="${file("${var.path}/analysiskey.json")}"
    project="fluted-anthem-331611"
    region="europe-west2"
}
