import { useEffect, useState } from 'react'

export default function Preloader() {
  const [visible, setVisible] = useState(true)

  useEffect(() => {
    const timer = setTimeout(() => setVisible(false), 600)
    return () => clearTimeout(timer)
  }, [])

  if (!visible) return null

  return (
    <div className="preloader">
      <div className="loader">
        <div className="shadow" />
        <div className="box" />
      </div>
    </div>
  )
}
