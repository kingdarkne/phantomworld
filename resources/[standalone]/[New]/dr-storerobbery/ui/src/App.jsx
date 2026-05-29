import { useEffect, useState } from 'react'

export default function App() {
  const [visible, setVisible] = useState(false)
  const [label, setLabel] = useState('Store')
  const [percent, setPercent] = useState(0)

  useEffect(() => {
    const handler = (event) => {
      const { action, data } = event.data || {}
      if (action === 'showRobbery') {
        setLabel(data?.label || 'Store')
        setPercent(0)
        setVisible(true)
      }
      if (action === 'updateProgress') {
        setPercent(Math.min(100, Math.max(0, data?.percent ?? 0)))
      }
      if (action === 'hideRobbery') {
        setVisible(false)
        setPercent(0)
      }
    }

    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  if (!visible) return null

  return (
    <div className="robbery-overlay">
      <div className="robbery-card pulse">
        <p className="eyebrow">Hold-up in progress</p>
        <h1>ROBBERY IN PROGRESS</h1>
        <p className="store-name">{label}</p>
        <div className="bar-track">
          <div className="bar-fill" style={{ width: `${percent}%` }} />
        </div>
        <p className="percent">{percent}%</p>
      </div>
    </div>
  )
}
