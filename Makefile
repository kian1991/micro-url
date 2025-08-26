AWS_REGION     ?= eu-central-1
AWS_ACCOUNT_ID ?= 877525430326

# Repo URLs
ECR_URL = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

SERVICES = shortening forwarding

# Build a single service
build:
	docker build --build-arg SERVICE=$(SERVICE)-service -t $(SERVICE)-service .

# Tag for ECR
tag:
	docker tag $(SERVICE)-service:latest $(ECR_URL)/$(SERVICE):latest

# Push to ECR
push: tag
	docker push $(ECR_URL)/$(SERVICE):latest

# Full flow for one service
deploy: build push

# Build & push all services (! We build for amd64 - platform indepent in case youre using ARM)
deploy-all:
	@for s in $(SERVICES); do \
		echo "Deploying $$s..."; \
		docker buildx build \
			--platform linux/amd64 \
			--build-arg SERVICE=$$s-service \
			--no-cache \
			-t $$s-service:latest .; \
		docker tag $$s-service:latest $(ECR_URL)/$$s:latest; \
		docker push $(ECR_URL)/$$s:latest; \
	done

# For debug only: forces redeployment if container images got altered
force-aws-redeploy:
	aws ecs update-service --cluster micro-url-cluster --service forwarding-ecs-service --force-new-deployment
	aws ecs update-service --cluster micro-url-cluster --service shortening-ecs-service --force-new-deployment

# Connect docker to AWS ECR
ecr-login:
	aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $(ECR_URL)
