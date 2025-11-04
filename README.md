
## 프로젝트 구조

```
2025_k8s/
├── backend/          # Django REST Framework 백엔드
│   ├── api/         # API 앱 (이름 저장/조회)
│   ├── config/      # Django 설정
│   └── manage.py
└── frontend/        # React + Vite 프론트엔드
    └── src/
```

### 백엔드 실행

1. 가상환경 생성 및 활성화
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate  # Windows
```

2. 의존성 설치
```bash
pip install -r requirements.txt
```

3. 데이터베이스 마이그레이션
```bash
python3 manage.py makemigrations
python3 manage.py migrate
```

4. 서버 실행
```bash
python3 manage.py runserver
```

백엔드가 `http://localhost:8000`에서 실행


### 프론트엔드 실행

1. 의존성 설치
```bash
cd frontend
npm install
```

2. 개발 서버 실행
```bash
npm run dev
```

프론트엔드가 `http://localhost:3000`에서 실행


## API 엔드포인트

- `GET /api/names/` - 이름 목록 조회
- `POST /api/names/` - 이름 저장
  ```json
  {
    "name": "홍길동"
  }
  ```

## 기능

- 이름 입력 및 저장
- 저장된 이름 목록 조회
- 생성일시 표시