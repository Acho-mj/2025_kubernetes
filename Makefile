# Makefile for Kubernetes Deployment Automation

# 환경변수 설정 (필요시 수정)
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
AWS_REGION ?= $(shell aws configure get region 2>/dev/null || echo "ap-northeast-2")
ECR_BACKEND_REPO ?= backend-app
ECR_FRONTEND_REPO ?= frontend-app
APP_NAME ?= k8s-app
NAMESPACE ?= default

# ECR 리포지토리 URI
ECR_BACKEND_URI = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_BACKEND_REPO)
ECR_FRONTEND_URI = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_FRONTEND_REPO)

.PHONY: help
help: ## 도움말 출력
	@echo "사용 가능한 명령어:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check-env
check-env: ## 환경 변수 확인
	@echo "=== 환경 변수 확인 ==="
	@echo "AWS_ACCOUNT_ID: $(AWS_ACCOUNT_ID)"
	@echo "AWS_REGION: $(AWS_REGION)"
	@echo "ECR_BACKEND_URI: $(ECR_BACKEND_URI)"
	@echo "ECR_FRONTEND_URI: $(ECR_FRONTEND_URI)"
	@echo "APP_NAME: $(APP_NAME)"
	@echo "NAMESPACE: $(NAMESPACE)"

.PHONY: ecr-login
ecr-login: ## ECR에 로그인
	@echo "=== ECR 로그인 ==="
	@aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

.PHONY: build-backend
build-backend: ## Backend Docker 이미지 빌드
	@echo "=== Backend 이미지 빌드 ==="
	docker build -t $(ECR_BACKEND_REPO):latest ./backend
	docker tag $(ECR_BACKEND_REPO):latest $(ECR_BACKEND_URI):latest

.PHONY: build-frontend
build-frontend: ## Frontend Docker 이미지 빌드
	@echo "=== Frontend 이미지 빌드 ==="
	docker build -t $(ECR_FRONTEND_REPO):latest ./frontend
	docker tag $(ECR_FRONTEND_REPO):latest $(ECR_FRONTEND_URI):latest

.PHONY: push-backend
push-backend: ecr-login ## Backend 이미지를 ECR에 푸시
	@echo "=== Backend 이미지 푸시 ==="
	docker push $(ECR_BACKEND_URI):latest

.PHONY: push-frontend
push-frontend: ecr-login ## Frontend 이미지를 ECR에 푸시
	@echo "=== Frontend 이미지 푸시 ==="
	docker push $(ECR_FRONTEND_URI):latest

.PHONY: build-all
build-all: build-backend build-frontend ## 모든 이미지 빌드

.PHONY: push-all
push-all: push-backend push-frontend ## 모든 이미지 푸시

.PHONY: build-push
build-push: build-all push-all ## 모든 이미지 빌드 및 푸시

.PHONY: update-values
update-values: ## values.yaml을 ECR 이미지 경로로 업데이트
	@echo "=== values.yaml 업데이트 ==="
	@if [ -z "$(AWS_ACCOUNT_ID)" ]; then \
		echo "오류: AWS_ACCOUNT_ID가 설정되지 않았습니다."; \
		echo "다음과 같이 설정하세요: export AWS_ACCOUNT_ID=123456789012"; \
		exit 1; \
	fi
	@sed -i.bak 's|repository: backend-app|repository: $(ECR_BACKEND_URI)|g' helm/values.yaml
	@sed -i.bak 's|repository: frontend-app|repository: $(ECR_FRONTEND_URI)|g' helm/values.yaml
	@sed -i.bak 's|pullPolicy: Never|pullPolicy: Always|g' helm/values.yaml
	@rm -f helm/values.yaml.bak
	@echo "values.yaml 업데이트 완료"

.PHONY: helm-dependency-update
helm-dependency-update: ## Helm 의존성 업데이트
	@echo "=== Helm 의존성 업데이트 ==="
	cd helm && helm dependency update

.PHONY: helm-install
helm-install: helm-dependency-update ## Helm 차트 설치
	@echo "=== Helm 차트 설치 ==="
	helm install $(APP_NAME) ./helm --namespace $(NAMESPACE) --create-namespace

.PHONY: helm-upgrade
helm-upgrade: helm-dependency-update ## Helm 차트 업그레이드
	@echo "=== Helm 차트 업그레이드 ==="
	helm upgrade $(APP_NAME) ./helm --namespace $(NAMESPACE)

.PHONY: helm-uninstall
helm-uninstall: ## Helm 차트 제거
	@echo "=== Helm 차트 제거 ==="
	helm uninstall $(APP_NAME) --namespace $(NAMESPACE)

.PHONY: deploy
deploy: build-push update-values helm-upgrade ## 전체 배포 (빌드 → 푸시 → 배포)

.PHONY: status
status: ## 배포 상태 확인
	@echo "=== 배포 상태 ==="
	@kubectl get pods -n $(NAMESPACE) -l app.kubernetes.io/instance=$(APP_NAME)
	@kubectl get services -n $(NAMESPACE) -l app.kubernetes.io/instance=$(APP_NAME)

.PHONY: logs-backend
logs-backend: ## Backend 로그 확인
	@kubectl logs -f -n $(NAMESPACE) -l app=backend --tail=100

.PHONY: logs-frontend
logs-frontend: ## Frontend 로그 확인
	@kubectl logs -f -n $(NAMESPACE) -l app=frontend --tail=100

