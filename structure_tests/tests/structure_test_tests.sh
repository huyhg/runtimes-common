#!/bin/bash

# Copyright 2017 Google Inc. All rights reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#Structure test tests. The tests to test the structure tests.

#End to end tests to make sure the structure tests do what we expect them
#to do on a known quantity, the latest debian docker image.

TEST_TAG="test_tag-$(date +%Y-%M-%d-%H%M%S)"
export FILE="debian_test.json"
export IMAGE="gcr.io/google-appengine/debian8:latest"
DOCKER_NAMESPACE=${DOCKER_NAMESPACE:-"gcr.io/gcp-runtimes"}
export STRUCTURE_TEST_IMAGE="${DOCKER_NAMESPACE}/structure-test-test:${TEST_TAG}"

failures=0
# build newest structure test image
pushd ..
./build.sh "${STRUCTURE_TEST_IMAGE}"
popd

# Run the debian tests, they should always pass on latest
envsubst < cloudbuild.yaml.in > cloudbuild.yaml
if ! gcloud container builds submit . --config=cloudbuild.yaml;
then
  echo "Success case test failed"
  failures=$((failures + 1))
fi

# Run some bogus tests, they should fail as expected
FILE="debian_failure_test.json"
envsubst < cloudbuild.yaml.in > cloudbuild.yaml
if gcloud container builds submit . --config=cloudbuild.yaml;
then
  echo "Failure case test failed"
  failures=$((failures + 1))
fi

# Run some structure tests on the structure test image itself
IMAGE="${STRUCTURE_TEST_IMAGE}"
FILE="structure_test_test.json"
envsubst < cloudbuild.yaml.in > cloudbuild.yaml
if ! gcloud container builds submit . --config=cloudbuild.yaml;
then
  echo "Structure test failed"
  failures=$((failures + 1))
fi

echo "Failure Count: $failures"
if [ "$failures" -gt "0" ]
then
  exit 1
fi
