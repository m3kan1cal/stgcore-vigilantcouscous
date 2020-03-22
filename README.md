## Vigilant Couscous introduction

This project was generated with [Angular CLI](https://github.com/angular/angular-cli) version 9.0.2. Assumptions in place for this walkthrough are that `ng` CLI and `npm` are installed at the appropriate versions.

## Development server for Angular

Run `npm i` to install all dependencies for the project.

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app will automatically reload if you change any of the source files.

Run `ng test --watch=false` to run Karma unit tests.

Run `ng e2e --port 4202` to run Protractor end-to-end tests.

Run `ng build` to build the project. The build artifacts will be stored in the `dist/` directory. Use the `--nonprod` flag for a nonproduction build.

Run `ng generate component component-name` to generate a new component. You can also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.

## Getting started with base AWS resources

To get going, there are a few AWS resources that need to be built. We're going to need a VPC, security groups, public/private subnets, NAT gateways, a public-facing ALB, and some container services. For the walkthrough, we're using two project names: 1) STG PillarOfAutumn (our base AWS network and resources) and 2) STG VigilantCouscous (our ECS Fargate service.)

To keep things secure, you need to register a domain (if you don't have one already) whose nameservers you can point to AWS nameservers. This domain will also be used in future security steps to get TLS certificates. We're not going to just be building a **Hello World** app being served over port 80; we're redirecting 80 traffic to 443 by default. There's very little value in showing anyone how to do anything that's insecure because too often that becomes **production**.

If you don't have a domain, go get one now at [NameCheap.com](https://www.namecheap.com/). For this walkthrough, it's going to reference a domain that our team already has registered (`stoictechgroup.com`), pointed to AWS nameservers, and created a **free** TLS certificate in AWS Certificate Manager.

Create the EC2 VPC with private/public subnets, route tables, public-facing ALB, and NAT gateways. Be sure to change the `s3-bucket` and `s3-prefix` parameter override values to S3 buckets that exist in your account and region. Update the `ACMARN` parameter override value to the ARN of the TLS certificate you've configured for this walkthrough. Also, change the `stack` name and `region` to what you prefer.

**Note:** AWS profiles are being used in all AWS CLI commands, so when you see something like `profile="stoic"` that is my own profile. Change these to match what your profiles are named.

```zsh
profile="stoic"
region="us-west-2"
stack="STGPillarOfAutumn-EC2-VPC-P-CF"

# Build VPC with public/private subnets.
aws cloudformation deploy --profile $profile \
    --stack-name $stack \
    --region $region \
    --template-file ./resources/vpc_tmpl.yml \
    --s3-bucket "stoic-nonprod-artifacts" \
    --s3-prefix "cloudformation/pillarofautumn/networking" \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides NumSubnets="2" \
        HasEndpoints="true" \
        ACMARN="arn:aws:acm:us-west-2:750444023825:certificate/3c0fe92e-f524-4be6-945f-940df62e6990" \
        AccountSet="stoic" \
        Environment="nonprod" \
        ApplicationVersion="1.0.0" \
        InfrastructureVersion="1.0.0"
```

Create the Route53 record set to link the public-facing ALB in the VPC with a friendly URL. Update the `HostedZoneName` and `Z284VH0H47FTBB` parameter override values with the Route53 hosted zone for the domain used in this walkthrough. The same rule applies here as above with respect to the `stack` name and `region`.

```zsh
profile="stoic"
region="us-west-2"
stack="STGPillarOfAutumn-Route53-ALB-P-CF"

# Build VPC with public/private subnets.
aws cloudformation deploy --profile $profile \
    --stack-name $stack \
    --region $region \
    --template-file ./resources/route53_tmpl.yml \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides VPCStack="STGPillarOfAutumn-EC2-VPC-P-CF" \
        HostedZoneName="stoictechgroup.com" \
        HostedZoneID="Z284VH0H47FTBB" \
        AccountSet="stoic" \
        Environment="nonprod" \
        ApplicationVersion="1.0.0" \
        InfrastructureVersion="1.0.0"
```

Create the ECS cluster in VPC for our Fargate services. This should be created before any repository or services are spun up. The same rule applies here as above with respect to the `stack` name and `region`.

```zsh
profile="stoic"
region="us-west-2"
stack="STGPillarOfAutumn-ECSCluster-P-CF"

# Build Fargate ECS cluster and security groups.
aws cloudformation deploy --profile $profile \
    --stack-name $stack \
    --region $region \
    --template-file ./resources/ecscluster_tmpl.yml \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides VPCStack="STGPillarOfAutumn-EC2-VPC-P-CF" \
        AccountSet="stoic" \
        Environment="nonprod" \
        ApplicationVersion="1.0.0" \
        InfrastructureVersion="1.0.0"
```

Create the AWS ECR repository for our Angular + NGINX service. This should be created before any services are spun up, and should map to the service being created in future steps. `RepositoryName` can be whatever you want to call it, but the pattern I follow is to call this repository the same as the GitHub repo I'm using as my reference. The same rule applies here as above with respect to the `stack` name and `region`.

**Note:** For the purposes of the walkthrough, we're doing something very insecure in the template used here. In the repository policy, we're saying something along the lines of `Principal: AWS: - '*'`. This is not a good practice. Before you deploy this anywhere outside of a nonprod environment, make sure you tighten up that principal to specific IAM users.

```zsh
profile="stoic"
region="us-west-2"
stack="STGVigilantCouscous-ECRRepository-LandingUI-P-CF"

# Build Fargate ECS cluster and security groups.
aws cloudformation deploy --profile $profile \
    --stack-name $stack \
    --region $region \
    --template-file ./resources/ecrrepository_tmpl.yml \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides RepositoryName="shouldroforion/stgcore-vigilantcouscous" \
        AccountSet="stoic" \
        Environment="nonprod" \
        ApplicationVersion="1.0.0" \
        InfrastructureVersion="1.0.0"
```

Once these are up in AWS, we're ready to move on to getting our Angular solution to build, run, image, tag, containerize, and deploy.

## Getting started with the Ng solution

Before running or building the solution, there are 2 things that you’ll potentially need to modify: Angular routing + NGINX setup for location & root directives. If you're just after a quickstart experience and are fine with serving your site up with a `/vigilantcouscous/` segment in your URL, then just skip ahead to [Working with AWS ECS and Fargate](#working-with-aws-ecs-and-fargate).

For routing, the solution is to build the app using `base-href` option. In the case of this project, make sure the `nonprod.dockerfile` is updated with a command that looks similar to this. Make sure the `vigilantcouscous` part is updated to be the subfolder/pattern you want the app served from. This comes in handy for path-based routing in AWS load balancers.

```zsh
ng build --base-href=/vigilantcouscous/ --output-path=dist
```

This build option will lead to the situation where the `index.html` of our app will have a BASE href defined accordingly to the path defined in the command.

```zsh
<base href=”/vigilantcouscous/” />
```

For the NGINX setup, you’ll have to override the default NGINX settings by using the following configuration. Do that overriding in the `default.conf` file used by Docker to customize the NGINX config when we build and run the image/container.

```zsh
location /vigilantcouscous/ {
    alias /var/www/html/vigilantcouscous/;
    try_files $uri$args $uri$args/ /vigilantcouscous/index.html;
}
```

Make sure the `vigilantcouscous` part is updated to be the subfolder/pattern you want the app served from. This comes in handy for path-based routing in AWS load balancers.

This combination of `ng build` command and NGINX setup has the following advantages:
- Viewers can access our apps through the configured subfolder/pattern URLs
- If you get on an Angular route, you can refresh pages without getting a 404

To stay consistent with the use of `vigilantcouscous` across NGINX and Angular, do a search and replace to find all usages of `vigilantcouscous` and update with the desired subfolder/pattern.

## Working with Docker

If all that checks out, move on to Docker and building for CI/CD and nonproduction. Depending on your OS, you're going to need Docker installed. Head to [Docker Desktop](https://www.docker.com/products/docker-desktop) and select the correction version for your OS. Once that install has completed, proceed to build and tag your image.

Build and tag the Docker image.

```zsh
docker image build -t shouldroforion/stgcore-vigilantcouscous:latest -f ./app.dockerfile .
```

Then, spin up the container once the build is done.

```zsh
docker container run -d -v ${PWD}:/app -v /app/node_modules -p 4201:4200 \
    --name stgcore-vigilantcouscous \
    --rm shouldroforion/stgcore-vigilantcouscous:latest
```

Run the unit and e2e tests.

```zsh
docker exec -it stgcore-vigilantcouscous ng test --watch=false
docker exec -it stgcore-vigilantcouscous ng e2e --port 4202
```

Stop the container once done.

```zsh
docker container stop stgcore-vigilantcouscous
```

Using the production Dockerfile, build and tag the Docker image.

```zsh
docker image build --no-cache -t shouldroforion/stgcore-vigilantcouscous:prod-latest -f ./prod.dockerfile .

region="us-west-2"
account="750444023825"
docker tag shouldroforion/stgcore-vigilantcouscous:prod-latest \
    $account.dkr.ecr.$region.amazonaws.com/shouldroforion/stgcore-vigilantcouscous:prod-latest
```

If you want to verify and run the production images in a container, you can run the following to spin up the prod container using our local image.

```zsh
docker container run -p 4201:80 \
    --name stgcore-vigilantcouscous-prod \
    --rm shouldroforion/stgcore-vigilantcouscous:prod-latest
```

Next we're going to push our production images to our AWS ECR that we created in earlier steps. To do that, we're going to need to get the `docker login` command to authenticate. Get login command for Docker login by using the following command.

```zsh
profile="stoic"
region="us-west-2"

eval "$(aws ecr get-login --profile $profile \
    --region $region \
    --no-include-email)"
```

After getting the `Login Succeeded` message at the command prompt, then push this image to the AWS ECR repository.

```zsh
region="us-west-2"
account="750444023825"

docker image push "$account.dkr.ecr.$region.amazonaws.com/shouldroforion/stgcore-vigilantcouscous:prod-latest"
```

At this point, we now have a production-ready Docker image pushed to our AWS ECR to use in our AWS ECS Fargate service.

## Working with AWS ECS and Fargate

This is where we manage our ECS Fargate service resources and stack. This should be created last and should reference the repository and cluster previously created. Note that for this service creation to succeed, the published image needs to exist at the correct `ImageUrl` location.

We're going to create the service so that it's deployed across multiple AZs in private subnets. The service will have any HTTP traffic automagically re-routed to HTTPS. We will also see the service shipping its logs off to AWS CloudWatch for centralized log management. Also, a container healthcheck will be embedded in the service task definition so we'll always be able to determine the health of our services easily. Using the patterns used in this service, we'll be able to deploy future services that rely on the same ALB to do path-based routing.

In general, the `ServiceName`, `Path`, and `ImageUrl` naming conventions should bear close resemblance to each other and match what was configured in the image being referenced for the service. The same rule applies here as above with respect to the `stack` name and `region`.

```zsh
profile="stoic"
region="us-west-2"
stack="STGVigilantCouscous-ECSService-LandingUI-P-CF"
account="750444023825"

# Build ECS task and container for .
aws cloudformation deploy --profile $profile \
    --stack-name $stack \
    --region $region \
    --template-file ./resources/ecsservice_tmpl.yml \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides VPCStack="STGPillarOfAutumn-EC2-VPC-P-CF" \
        ECSStack="STGPillarOfAutumn-ECSCluster-P-CF" \
        ServiceName="LandingUI" \
        ImageUrl="$account.dkr.ecr.$region.amazonaws.com/shouldroforion/stgcore-vigilantcouscous:prod-latest" \
        Path="vigilantcouscous" \
        NumZones="2" \
        AccountSet="stoic" \
        Environment="nonprod" \
        ApplicationVersion="1.0.0" \
        InfrastructureVersion="1.0.0"
```

At this point we've deployed a service on ECS for AWS Fargate, hosted across multiple private subnets, and is accessible via the public-facing ALB we created above in our VPC stack. You should be able to visit your full blown DevOps/Cloud Migration profile by visiting `https://albx.<yourdomain>.com/vigilantcouscous/`. Customize to your liking.

Once we've made updates to our future solution images and pushed them to the repository, we're going to force the service to update with the newest image in repository. Note this assumes the `STGPillarOfAutumn` stack has been created in our account, along with ECS service for `STGVigilantCouscous`.

```zsh
profile="stoic"
region="us-west-2"
cluster="STGPillarOfAutumn-ECSCluster"
service="STGVigilantCouscous-LandingUIECSService"

aws ecs update-service --profile $profile \
    --region $region \
    --cluster $cluster \
    --service $service \
    --force-new-deployment
```

For **Stoic Technology Group**, we run our main landing page using an architecture very similar to this walkthrough. Check it out at https://alb1.stoictechgroup.com/requiem/#/landing.

## Further help

To get more help on the Angular CLI use `ng help` or go check out the [Angular CLI README](https://github.com/angular/angular-cli/blob/master/README.md).
