import { motion } from "motion/react"
import { parseText } from "@/lib/utils"

const renderParsedText = (parsedText) => {
    return parsedText.map((part, index) => {
        if (part.type === "text") {
            return <span key={index}>{part.content}</span>
        }
        if (part.type === "element" && part.tag === "span") {
            return (
                <motion.span key={index} className={part.props.className}>
                    {part.children}
                </motion.span>
            )
        }
        return null
    })
}

const LoadingTips = ({ currentTip, config }) => {
    return (
        <motion.div 
            className="mt-8 text-center"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
        >
            <motion.p 
                className="text-sm text-muted-foreground mb-2"
                whileHover={{ scale: 1.02 }}
            >
                {renderParsedText(parseText(config.strings.proTipLabel))}
            </motion.p>
            <motion.p 
                className="text-foreground text-balance"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.2 }}
            >
                {renderParsedText(parseText(currentTip))}
            </motion.p>
        </motion.div>
    )
}

export default LoadingTips