import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

const API_BASE_URL = 'http://localhost:8000/api'

function App() {
  const [name, setName] = useState('')
  const [names, setNames] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // 이름 목록 조회
  const fetchNames = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${API_BASE_URL}/names/`)
      // Django REST Framework는 배열을 직접 반환하거나 results 필드에 담을 수 있음
      const data = Array.isArray(response.data) ? response.data : (response.data.results || response.data)
      setNames(data)
      setError('')
    } catch (err) {
      let errorMsg = '이름 목록을 불러오는데 실패했습니다.'
      if (err.response?.data) {
        if (err.response.data.error) {
          errorMsg = `${err.response.data.error}: ${err.response.data.detail || ''}`
        } else if (err.response.data.detail) {
          errorMsg = err.response.data.detail
        } else if (typeof err.response.data === 'string') {
          errorMsg = err.response.data
        }
      }
      setError(errorMsg)
      console.error('목록 조회 에러 상세:', err.response?.data || err)
      if (err.response?.data?.traceback) {
        console.error('트레이스백:', err.response.data.traceback)
      }
    } finally {
      setLoading(false)
    }
  }

  // 이름 저장
  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) {
      setError('이름을 입력해주세요.')
      return
    }

    try {
      setLoading(true)
      setError('')
      const response = await axios.post(`${API_BASE_URL}/names/`, { name: name.trim() })
      console.log('저장 성공:', response.data)
      setName('')
      // 저장 후 목록 새로고침
      await fetchNames()
    } catch (err) {
      // 에러 메시지 상세 표시
      let errorMsg = '이름 저장에 실패했습니다.'
      if (err.response) {
        // 서버 응답이 있는 경우
        if (err.response.data) {
          if (err.response.data.error) {
            errorMsg = `${err.response.data.error}: ${err.response.data.detail || ''}`
          } else if (err.response.data.name) {
            errorMsg = `이름 필드 오류: ${err.response.data.name.join(', ')}`
          } else if (err.response.data.detail) {
            errorMsg = err.response.data.detail
          } else if (typeof err.response.data === 'string') {
            errorMsg = err.response.data
          } else {
            errorMsg = JSON.stringify(err.response.data)
          }
        } else {
          errorMsg = `서버 오류: ${err.response.status} ${err.response.statusText}`
        }
      } else if (err.request) {
        errorMsg = '서버에 연결할 수 없습니다. 백엔드가 실행 중인지 확인하세요.'
      } else {
        errorMsg = err.message || '알 수 없는 오류가 발생했습니다.'
      }
      setError(errorMsg)
      console.error('저장 에러 상세:', {
        message: err.message,
        response: err.response?.data,
        status: err.response?.status,
      })
      if (err.response?.data?.traceback) {
        console.error('트레이스백:', err.response.data.traceback)
      }
    } finally {
      setLoading(false)
    }
  }

  // 컴포넌트 마운트 시 목록 조회
  useEffect(() => {
    fetchNames()
  }, [])

  return (
    <div className="app">
      <div className="container">
        <h1>이름 저장</h1>
        
        {/* 이름 입력 폼 */}
        <form onSubmit={handleSubmit} className="form">
          <div className="input-group">
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="이름을 입력하세요"
              disabled={loading}
              className="input"
            />
            <button 
              type="submit" 
              disabled={loading || !name.trim()}
              className="button"
            >
              {loading ? '저장 중...' : '저장'}
            </button>
          </div>
        </form>

        {/* 에러 메시지 */}
        {error && <div className="error">{error}</div>}

        {/* 이름 목록 */}
        <div className="list-container">
          <h2>저장된 이름 목록 ({names.length})</h2>
          {loading && names.length === 0 ? (
            <div className="loading">로딩 중...</div>
          ) : names.length === 0 ? (
            <div className="empty">저장된 이름이 없습니다.</div>
          ) : (
            <ul className="name-list">
              {names.map((item) => (
                <li key={item.id} className="name-item">
                  <span className="name">{item.name}</span>
                  <span className="date">
                    {new Date(item.created_at).toLocaleString('ko-KR')}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  )
}

export default App

