import { memo } from "react"

const Particles = memo(({ config }) => {
    if (!config.particles.enabled) return null
    const particles = Array.from({ length: config.particles.count }, (_, i) => i)
    return (
        <div className="absolute inset-0">
            {particles.map((particle) => (
                <div
                    key={particle}
                    className="absolute w-1 h-1 bg-primary/20 rounded-full animate-pulse"
                    style={{
                        left: `${Math.random() * 100}%`,
                        top: `${Math.random() * 100}%`,
                        animationDelay: `${Math.random() * 3}s`,
                        animationDuration: `${2 + Math.random() * 3}s`,
                    }}
                />
            ))}
        </div>
    )
})

export default Particles