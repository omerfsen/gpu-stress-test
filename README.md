# gpu-stress-test

This is a simple piece of PyTorch code to stress test a GPU with a default run-time of 5 minutes. This test ran against A100 GPU

Component versions:


| Component              | Version      |
| -----------            | -----------  |
| Ubuntu                 | 20.04.4 LTS  |
| PYTHON_VERSION         | 3.10.5       |
| PYTHON_PIP_VERSION     | 22.1.2       |
| pip3 torch             | 1.12.0+cu116 |
| torchvision            | 0.13.0+cu116 |
| torchaudio             | 0.12.0+cu116 |
| cuda-python            | 11.6.1       |
| cuda                   | cuda:11.0.3  |

* Pytorch does not support `Cuda 11.7` yet so we have used previous version `11.0.3` You can check https://download.pytorch.org/whl/torch_stable.html



## Buildx building and pushing to Dockerhub

```bash
docker buildx build -t waggle/gpu-stress-test:latest --platform linux/amd64,linux/arm64 --push .
```

## Build the Docker images
```bash
docker build -t omerfsen/gpu-stress-test:latest .
```

> *Note*: the image is auto-built by the CI and uploaded to Dockerhub (https://hub.docker.com/r/omerfsen/gpu-stress-test/tags)

## Run on device

### Docker Usage
Default run-time:
```bash
docker run -it --rm --runtime nvidia --network host omerfsen/gpu-stress-test:latest
```

Over-ride run-time to 2 minutes:
```bash
docker run -it --rm --runtime nvidia --network host omerfsen/gpu-stress-test:latest -m 2
```

When runnng docker image, when you issue `nvidia-smi` you can see it consumes GPU

```bash
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A    139964      C   python3                          1107MiB |
+-----------------------------------------------------------------------------+
root@nvidia-aie-PassTHRU3:~/gpu-stress-test# nvidia-smi 
Sun Jul 17 14:06:02 2022       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.48.07    Driver Version: 515.48.07    CUDA Version: 11.7     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA A100-PCI...  Off  | 00000000:0B:00.0 Off |                    0 |
| N/A   44C    P0   167W / 250W |   1109MiB / 40960MiB |    100%      Default |
|                               |                      |             Disabled |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A    139964      C   python3                          1107MiB |
+-----------------------------------------------------------------------------+
```


### Kubernetes Usage
Default run-time:
```bash
kubectl run gpu-test --image=omerfsen/gpu-stress-test:1.0.0 --attach=true
```
> *Note*: delete the running `kubernetes` pod via: `kubectl delete pod gpu-test`



## Run as a Kubernetes Cronjob
The cronjob is meant to run the gpu stress in a periodic fashion.
```bash
kubectl create -f cronjob.yaml
```

Check if it was created:
```bash
kubectl get cronjobs
```

Watch until one is created:
```bash
kubectl get jobs --watch
```

Delete cronjob:
```bash
kubectl delete -f cronjob.yaml
```
