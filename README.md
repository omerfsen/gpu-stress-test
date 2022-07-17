# gpu-stress-test

This is a simple piece of PyTorch code to stress test a GPU with a default run-time of 5 minutes.

## Buildx building and pushing to Dockerhub

```bash
docker buildx build -t waggle/gpu-stress-test:latest --platform linux/amd64,linux/arm64 --push .
```

## Build the Docker images
```bash
docker build -t waggle/gpu-stress-test:latest .
```

> *Note*: the image is auto-built by the CI and uploaded to Dockerhub (https://hub.docker.com/r/waggle/gpu-stress-test/tags)

## Run on device

### Docker Usage
Default run-time:
```bash
docker run -it --rm --runtime nvidia --network host waggle/gpu-stress-test:latest
```

Over-ride run-time to 2 minutes:
```bash
docker run -it --rm --runtime nvidia --network host waggle/gpu-stress-test:latest -m 2
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
kubectl run gpu-test --image=waggle/gpu-stress-test:1.0.0 --attach=true
```
> *Note*: delete the running `kubernetes` pod via: `kubectl delete pod gpu-test`

### Pluginctl Usage
Default run-time
```bash
pluginctl deploy --name gpu-test2 --selector resource.gpu=true waggle/gpu-stress-test:1.0.0
```

Over-ride run-time to 1 minute:
```bash
pluginctl deploy --name gpu-test2 --selector resource.gpu=true waggle/gpu-stress-test:1.0.0 -- -m 1
```

> Note: the source code for the Waggle `pluginctl` tool can be found here: https://github.com/waggle-sensor/edge-scheduler


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
