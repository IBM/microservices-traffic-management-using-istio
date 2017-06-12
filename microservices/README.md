# Building the images of the Microservices

> This steps uses the Bluemix Registry hence the extra prefix of registry.ng.bluemix.net. For Docker Hub, just use your username as the prefix.

## Details image

1. Build the image using the Dockerfile in `details` folder.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/details-v1 .
```
2. Push the image.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/details-v1
```

## Ratings image

1. Build the image using the Dockerfile in `ratings` folder.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/ratings-v1
```
2. Push the image.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/ratings-v1
```

## Reviews images
> There are 3 versions of the reviews service so you will build three Docker images.

1. Build the images using the Dockerfile in `reviews` folder. Follow the build arguments.
```bash
$ gradle build
$ cd reviews-wlpcfg
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v1 --build-arg service_version=v1 .
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v2 --build-arg service_version=v2 --build-arg enable_ratings=true .
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v3 --build-arg service_version=v3 --build-arg enable_ratings=true --build-arg star_color=red .
```

2. Push the images.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v1
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v2
$ docker build -t registry.ng.bluemix.net/<your-namespace>/reviews-v3
```

## MySQL Data generator

1. Build the images using the Dockerfile in `mysql_data` folder.
```bash
$ docker build -t registry.ng.bluemix.net/<your-namespace>/mysql-bookinfo .
```

2. Push the image.
```bash
$ docker push registry.ng.bluemix.net/<your-namespace>/mysql-bookinfo
```
