// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

local common = import '../common.libsonnet';
local mixins = import 'templates/mixins.libsonnet';
local tpus = import 'templates/tpus.libsonnet';
{
  runFlaxLatest:: common.JaxTest + common.jaxlibLatest + common.libtpuAlpha {
    local config = self,

    frameworkPrefix: 'flax-latest',
    extraDeps:: '',
    extraFlags:: '',

    testScript:: |||
      set -x
      set -u
      set -e

      # .bash_logout sometimes causes a spurious bad exit code, remove it.
      rm .bash_logout

      pip install --upgrade pip
      %(installLatestJax)s
      %(maybeBuildJaxlib)s
      %(printDiagnostics)s

      pip install --upgrade clu %(extraDeps)s

      num_devices=`python3 -c "import jax; print(jax.device_count())"`
      if [ "$num_devices" = "1" ]; then
        echo "No TPU devices detected"
        exit 1
      fi

      git clone https://github.com/google/flax
      cd flax
      pip install -e .
      cd examples/%(modelName)s

      export GCS_BUCKET=$(MODEL_DIR)
      export TFDS_DATA_DIR=$(TFDS_DIR)

      python3 main.py --workdir=$(MODEL_DIR)  --config=configs/%(extraConfig)s %(extraFlags)s
    ||| % (self.scriptConfig {
             modelName: config.modelName,
             extraDeps: config.extraDeps,
             extraConfig: config.extraConfig,
             extraFlags: config.extraFlags,
           }),
  },
  PodFlaxLatest:: common.JaxPodTest + common.jaxlibLatest + common.libtpuAlpha {
    local config = self,
    frameworkPrefix: 'flax-latest',
    extraDeps:: '',
    extraFlags:: '',

    testScript:: |||
      set -x
      set -u
      set -e
      # .bash_logout sometimes causes a spurious bad exit code, remove it.
      rm .bash_logout
      pip install --upgrade pip
      %(installLatestJax)s
      %(maybeBuildJaxlib)s
      %(printDiagnostics)s
      pip install --upgrade clu %(extraDeps)s
      git clone https://github.com/google/flax
      cd flax
      pip install -e .
      cd examples/%(modelName)s
      export GCS_BUCKET=$(MODEL_DIR)
      export TFDS_DATA_DIR=$(TFDS_DIR)
      python3 main.py --workdir=$(MODEL_DIR)  --config=configs/%(extraConfig)s %(extraFlags)s
    ||| % (self.scriptConfig {
             modelName: config.modelName,
             extraDeps: config.extraDeps,
             extraConfig: config.extraConfig,
             extraFlags: config.extraFlags,
           }),
  },
}
