#!/bin/bash

# Kubernetes 배포 자동화 스크립트
# 사용법: ./deploy.sh [옵션]

# set -e는 나중에 설정 (AWS CLI 체크 후)

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 환경 변수 설정
AWS_PROFILE=${AWS_PROFILE:-choimjAI}
AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query Account --output text 2>/dev/null)}
AWS_REGION=${AWS_REGION:-$(aws configure get region --profile ${AWS_PROFILE} 2>/dev/null || echo "ap-northeast-2")}
ECR_BACKEND_REPO=${ECR_BACKEND_REPO:-backend-app}
ECR_FRONTEND_REPO=${ECR_FRONTEND_REPO:-frontend-app}
APP_NAME=${APP_NAME:-k8s-app}
NAMESPACE=${NAMESPACE:-default}
IMAGE_TAG=${IMAGE_TAG:-latest}

# ECR URI
ECR_BACKEND_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_BACKEND_REPO}"
ECR_FRONTEND_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_FRONTEND_REPO}"

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 환경 변수 확인
check_env() {
    log_info "환경 변수 확인 중"
    
    # PATH 설정
    export PATH="$HOME/.local/bin:$PATH"
    
    # AWS CLI 설치 확인
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI가 설치되어 있지 않습니다."
        echo ""
        echo "AWS CLI 설치 방법:"
        echo "  curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\""
        echo "  unzip awscliv2.zip"
        echo "  sudo ./aws/install"
        echo ""
        echo "또는 AWS 계정 ID를 직접 설정하세요:"
        echo "  export AWS_ACCOUNT_ID=123456789012"
        exit 1
    fi
    
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        log_error "AWS_ACCOUNT_ID가 설정되지 않았습니다."
        echo "다음 중 하나를 실행하세요:"
        echo "  export AWS_ACCOUNT_ID=123456789012"
        echo "  또는 AWS CLI를 설정하고 aws sso login을 실행하세요"
        exit 1
    fi
    
    log_info "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
    log_info "AWS_REGION: $AWS_REGION"
    log_info "ECR_BACKEND_URI: $ECR_BACKEND_URI"
    log_info "ECR_FRONTEND_URI: $ECR_FRONTEND_URI"
    log_info "APP_NAME: $APP_NAME"
    log_info "NAMESPACE: $NAMESPACE"
}

# ECR 로그인
ecr_login() {
    log_info "ECR 로그인 중"
    export PATH="$HOME/.local/bin:$PATH"
    # Docker 권한 확인
    if ! docker ps &> /dev/null; then
        log_warn "Docker 권한이 없습니다. sudo를 사용합니다."
        aws ecr get-login-password --profile ${AWS_PROFILE} --region "$AWS_REGION" | \
            sudo docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    else
        aws ecr get-login-password --profile ${AWS_PROFILE} --region "$AWS_REGION" | \
            docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    fi
}

# Docker 이미지 빌드
build_image() {
    local service=$1
    local repo=$2
    local uri=$3
    
    log_info "${service} 이미지 빌드 중"
    # Docker 권한 확인
    if ! docker ps &> /dev/null; then
        log_warn "Docker 권한이 없습니다. sudo를 사용합니다."
        sudo docker build -t "${repo}:${IMAGE_TAG}" "./${service}"
        sudo docker tag "${repo}:${IMAGE_TAG}" "${uri}:${IMAGE_TAG}"
    else
        docker build -t "${repo}:${IMAGE_TAG}" "./${service}"
        docker tag "${repo}:${IMAGE_TAG}" "${uri}:${IMAGE_TAG}"
    fi
    log_info "${service} 이미지 빌드 완료: ${uri}:${IMAGE_TAG}"
}

# Docker 이미지 푸시
push_image() {
    local service=$1
    local uri=$2
    
    log_info "${service} 이미지 푸시 중"
    # Docker 권한 확인
    if ! docker ps &> /dev/null; then
        log_warn "Docker 권한이 없습니다. sudo를 사용합니다."
        sudo docker push "${uri}:${IMAGE_TAG}"
    else
        docker push "${uri}:${IMAGE_TAG}"
    fi
    log_info "${service} 이미지 푸시 완료"
}

# values.yaml 업데이트
update_values() {
    log_info "values.yaml 업데이트 중"
    
    # 백업 생성
    cp helm/values.yaml helm/values.yaml.bak
    
    # 이미지 경로 업데이트
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|repository: backend-app|repository: ${ECR_BACKEND_URI}|g" helm/values.yaml
        sed -i '' "s|repository: frontend-app|repository: ${ECR_FRONTEND_URI}|g" helm/values.yaml
        sed -i '' "s|pullPolicy: Never|pullPolicy: Always|g" helm/values.yaml
    else
        # Linux
        sed -i "s|repository: backend-app|repository: ${ECR_BACKEND_URI}|g" helm/values.yaml
        sed -i "s|repository: frontend-app|repository: ${ECR_FRONTEND_URI}|g" helm/values.yaml
        sed -i "s|pullPolicy: Never|pullPolicy: Always|g" helm/values.yaml
    fi
    
    log_info "values.yaml 업데이트 완료"
}

# ECR 인증 Secret 생성
create_ecr_secret() {
    log_info "ECR 인증 Secret 생성 중"
    export PATH="$HOME/.local/bin:$PATH"
    
    # 기존 Secret 삭제 (있는 경우)
    kubectl delete secret ecr-registry-secret -n "$NAMESPACE" 2>/dev/null || true
    
    # ECR 로그인 토큰으로 Secret 생성
    kubectl create secret docker-registry ecr-registry-secret \
        --docker-server="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" \
        --docker-username=AWS \
        --docker-password=$(aws ecr get-login-password --profile ${AWS_PROFILE} --region "$AWS_REGION") \
        --docker-email=none \
        --namespace="$NAMESPACE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "ECR 인증 Secret 생성 완료"
        # ServiceAccount에 Secret 연결
        kubectl patch serviceaccount default -n "$NAMESPACE" -p "{\"imagePullSecrets\":[{\"name\":\"ecr-registry-secret\"}]}" 2>/dev/null || true
    else
        log_warn "ECR Secret 생성 실패 (이미 존재할 수 있음)"
    fi
}

# Helm 의존성 업데이트
helm_dependency_update() {
    log_info "Helm 의존성 업데이트 중"
    cd helm && helm dependency update && cd ..
    log_info "Helm 의존성 업데이트 완료"
}

# Helm 설치
helm_install() {
    log_info "Helm 차트 설치 중"
    helm install "$APP_NAME" ./helm --namespace "$NAMESPACE" --create-namespace --timeout 15m
    log_info "Helm 차트 설치 완료"
}

# Helm 업그레이드
helm_upgrade() {
    log_info "Helm 차트 업그레이드 중"
    if helm upgrade "$APP_NAME" ./helm --namespace "$NAMESPACE" --timeout 15m 2>&1; then
        log_info "Helm 차트 업그레이드 완료"
        return 0
    else
        log_warn "Helm 차트 업그레이드 실패 (설치되지 않은 경우)"
        return 1
    fi
}

# 배포 상태 확인
check_status() {
    log_info "배포 상태 확인 중"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$APP_NAME"
    kubectl get services -n "$NAMESPACE" -l app.kubernetes.io/instance="$APP_NAME"
}

# 메인 함수
main() {
    local action=${1:-all}
    
    # 이제 set -e 활성화 (AWS CLI 체크 후)
    set -e
    
    check_env
    
    case $action in
        check)
            check_env
            ;;
        login)
            ecr_login
            ;;
        build)
            build_image "backend" "$ECR_BACKEND_REPO" "$ECR_BACKEND_URI"
            build_image "frontend" "$ECR_FRONTEND_REPO" "$ECR_FRONTEND_URI"
            ;;
        push)
            ecr_login
            push_image "backend" "$ECR_BACKEND_URI"
            push_image "frontend" "$ECR_FRONTEND_URI"
            ;;
        update-values)
            update_values
            ;;
        deploy)
            log_info "전체 배포 시작"
            ecr_login
            build_image "backend" "$ECR_BACKEND_REPO" "$ECR_BACKEND_URI"
            build_image "frontend" "$ECR_FRONTEND_REPO" "$ECR_FRONTEND_URI"
            push_image "backend" "$ECR_BACKEND_URI"
            push_image "frontend" "$ECR_FRONTEND_URI"
            update_values
            create_ecr_secret
            helm_dependency_update
            if ! helm_upgrade; then
                log_info "기존 배포가 없어 새로 설치합니다"
                helm_install
            fi
            sleep 5
            check_status
            log_info "배포 완료"
            ;;
        all)
            log_info "전체 프로세스 시작"
            ecr_login
            build_image "backend" "$ECR_BACKEND_REPO" "$ECR_BACKEND_URI"
            build_image "frontend" "$ECR_FRONTEND_REPO" "$ECR_FRONTEND_URI"
            push_image "backend" "$ECR_BACKEND_URI"
            push_image "frontend" "$ECR_FRONTEND_URI"
            update_values
            create_ecr_secret
            helm_dependency_update
            if ! helm_upgrade; then
                log_info "기존 배포가 없어 새로 설치합니다"
                helm_install
            fi
            sleep 5
            check_status
            log_info "전체 프로세스 완료"
            ;;
        *)
            echo "사용법: $0 [check|login|build|push|update-values|deploy|all]"
            echo ""
            echo "명령어:"
            echo "  check         - 환경 변수 확인"
            echo "  login         - ECR 로그인"
            echo "  build         - Docker 이미지 빌드"
            echo "  push          - Docker 이미지 푸시"
            echo "  update-values - values.yaml 업데이트"
            echo "  deploy        - 빌드 → 푸시 → 배포"
            echo "  all           - 전체 프로세스 (기본값)"
            exit 1
            ;;
    esac
}

main "$@"

