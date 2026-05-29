import { useEffect, useState } from 'react'

const MODE_META = {
  register: {
    badge: 'TILL',
    eyebrow: 'Emptying register',
    accent: 'register',
    hint: 'Grab the cash — stay at the till',
  },
  clerk: {
    badge: 'CLERK',
    eyebrow: 'Hold-up in progress',
    accent: 'clerk',
    hint: 'Keep the clerk intimidated',
  },
  safe: {
    badge: 'VAULT',
    eyebrow: 'Safe breach',
    accent: 'safe',
    hint: 'Loot the safe before police arrive',
  },
}

function getModeMeta(mode) {
  return MODE_META[mode] || MODE_META.register
}

export default function App() {
  const [visible, setVisible] = useState(false)
  const [label, setLabel] = useState('Store')
  const [phase, setPhase] = useState('Robbery in progress')
  const [percent, setPercent] = useState(0)
  const [cash, setCash] = useState(0)
  const [mode, setMode] = useState('register')

  useEffect(() => {
    const handler = (event) => {
      const { action, data } = event.data || {}

      if (action === 'showRobbery') {
        setLabel(data?.label || 'Store')
        setPhase(data?.phase || 'Robbery in progress')
        setMode(data?.mode || 'register')
        setPercent(0)
        setCash(0)
        setVisible(true)
      }

      if (action === 'updateProgress') {
        setPercent(Math.min(100, Math.max(0, data?.percent ?? 0)))
        if (data?.phase) setPhase(data.phase)
        if (typeof data?.cash === 'number') setCash(data.cash)
        if (data?.mode) setMode(data.mode)
      }

      if (action === 'hideRobbery') {
        setVisible(false)
        setPercent(0)
        setCash(0)
      }
    }

    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [])

  if (!visible) return null

  const meta = getModeMeta(mode)

  return (
    <div className={`robbery-overlay accent-${meta.accent}`}>
      <div className="robbery-card pulse">
        <div className="robbery-header">
          <span className="badge">{meta.badge}</span>
          <p className="eyebrow">{meta.eyebrow}</p>
        </div>
        <h1>{label}</h1>
        <p className="phase">{phase}</p>
        <div className="cash-row">
          <span className="cash-label">
            {mode === 'safe' ? 'Loot value' : 'Cash secured'}
          </span>
          <span className="cash-value">${cash.toLocaleString()}</span>
        </div>
        <div className="bar-track">
          <div className="bar-fill" style={{ width: `${percent}%` }} />
        </div>
        <div className="footer-row">
          <span className="hint">{meta.hint}</span>
          <span className="percent">{percent}%</span>
        </div>
      </div>
    </div>
  )
}
