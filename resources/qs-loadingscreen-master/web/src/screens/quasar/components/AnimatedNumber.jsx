import { useEffect } from "react"
import { animate, motion, useMotionValue, useTransform } from "motion/react"

const AnimatedNumber = ({ value, isMini = false }) => {
    const count = useMotionValue(0)
    const rounded = useTransform(() => Math.round(count.get()))

    useEffect(() => {
        const controls = animate(count, value, { duration: 2 })
        return () => controls.stop()
    }, [value])

    return <motion.span className={isMini ? "text-[8px] font-semibold text-foreground" : "text-xl font-bold text-foreground"}>{rounded}</motion.span>
}

export default AnimatedNumber