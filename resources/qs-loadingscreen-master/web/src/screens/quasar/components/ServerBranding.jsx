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

const ServerBranding = ({ config, isMini = false }) => {
    const logoSize = isMini ? "h-6 w-auto" : config.server.titleMode === "image" ? "h-36 w-auto" : "h-28 w-auto"
    const titleSize = isMini ? "text-sm" : "text-6xl"
    const nameSize = isMini ? "text-[8px]" : "text-lg"
    const subtitleSize = isMini ? "text-[8px]" : "text-sm"
    const dotSize = isMini ? "w-1 h-1" : "w-2 h-2"

    return (
        <div className={`text-left ${isMini ? "flex items-center gap-2" : "text-center mb-12"}`}>
            {(config.server.titleMode === "image" || config.server.titleMode === "mixed") && (
                <motion.img
                    src={config.server.logoUrl}
                    alt="Server Logo"
                    className={`${isMini ? logoSize : `mx-auto ${logoSize}`}`}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8 }}
                />
            )}
            <div>
                <motion.h1 
                    className={`${titleSize} font-bold text-foreground ${isMini ? "" : "tracking-wider"}`}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, delay: 0.2 }}
                >
                    {renderParsedText(parseText(config.server.title))}
                </motion.h1>
                {!isMini && (
                    <>
                        <motion.div 
                            className="flex items-center justify-center gap-1 mb-2"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ duration: 0.8, delay: 0.4 }}
                        >
                            <motion.div className={`${dotSize} bg-primary rounded-full animate-pulse`} 
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.5, delay: 0.6 }}
                            />
                            <motion.p className={`text-muted-foreground ${nameSize}`}>
                                {renderParsedText(parseText(config.server.name))}
                            </motion.p>
                            <motion.div className={`${dotSize} bg-primary rounded-full animate-pulse`} 
                                initial={{ scale: 0 }}
                                animate={{ scale: 1 }}
                                transition={{ duration: 0.5, delay: 0.6 }}
                            />
                        </motion.div>
                        <motion.p 
                            className={`text-muted-foreground ${subtitleSize}`}
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ duration: 0.8, delay: 0.6 }}
                        >
                            {renderParsedText(parseText(config.server.subtitle))}
                        </motion.p>
                    </>
                )}
            </div>
        </div>
    )
}

export default ServerBranding