import { motion } from "motion/react"
import { Card } from "@/components/ui/card"
import { Users, Shield, Zap } from "lucide-react"
import AnimatedNumber from "./AnimatedNumber"
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

const ServerInfoCards = ({ config, playerCount, maxPlayers, avgPing, serverStatus, isMini = false }) => {
    if (!isMini) {
        return (
            <motion.div 
                className="grid grid-cols-1 md:grid-cols-3 gap-4"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, staggerChildren: 0.1 }}
            >
                <motion.div variants={{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }}>
                    <Card className="bg-card/70 backdrop-blur-sm border-border/30 p-4 text-center hover:bg-card/70 transition-colors">
                        <motion.div whileHover={{ scale: 1.1 }} whileTap={{ scale: 0.95 }}>
                            <Users className="w-6 h-6 text-primary mx-auto mb-2" />
                        </motion.div>
                        <p className="text-sm text-muted-foreground mb-2">{renderParsedText(parseText(config.strings.playersOnline))}</p>
                        <p className="text-xl font-bold text-foreground">
                            <AnimatedNumber value={playerCount} isMini={isMini} />/<AnimatedNumber value={maxPlayers} isMini={isMini} />
                        </p>
                    </Card>
                </motion.div>
                <motion.div variants={{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }}>
                    <Card className="bg-card/70 backdrop-blur-sm border-border/30 p-4 text-center hover:bg-card/70 transition-colors">
                        <motion.div whileHover={{ scale: 1.1 }} whileTap={{ scale: 0.95 }}>
                            <Shield className="w-6 h-6 text-secondary mx-auto mb-2" />
                        </motion.div>
                        <p className="text-sm text-muted-foreground mb-2">{renderParsedText(parseText(config.strings.serverStatus))}</p>
                        <motion.p 
                            className="text-xl font-bold text-primary"
                            whileHover={{ scale: 1.05 }}
                        >
                            {renderParsedText(parseText(serverStatus))}
                        </motion.p>
                    </Card>
                </motion.div>
                <motion.div variants={{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } }}>
                    <Card className="bg-card/70 backdrop-blur-sm border-border/30 p-4 text-center hover:bg-card/70 transition-colors">
                        <motion.div whileHover={{ scale: 1.1 }} whileTap={{ scale: 0.95 }}>
                            <Zap className="w-6 h-6 text-primary mx-auto mb-2" />
                        </motion.div>
                        <p className="text-sm text-muted-foreground mb-2">{renderParsedText(parseText(config.strings.ping))}</p>
                        <p className="text-xl font-bold text-foreground">
                            <AnimatedNumber value={avgPing} isMini={isMini} />ms
                        </p>
                    </Card>
                </motion.div>
            </motion.div>
        )
    } else {
        return (
            <motion.div 
                className="flex gap-2 justify-end whitespace-nowrap"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6 }}
            >
                <motion.div className="flex items-center gap-1 hover:scale-105 transition-transform" whileHover={{ scale: 1.05 }}>
                    <Users className="w-3 h-3 text-primary" />
                    <div>
                        <p className="text-[8px] text-muted-foreground">{renderParsedText(parseText(config.strings.playersOnline))}</p>
                        <p className="text-[8px] font-semibold text-foreground">
                            <AnimatedNumber value={playerCount} isMini={isMini} />/<AnimatedNumber value={maxPlayers} isMini={isMini} />
                        </p>
                    </div>
                </motion.div>
                <motion.div className="flex items-center gap-1 hover:scale-105 transition-transform" whileHover={{ scale: 1.05 }}>
                    <Shield className="w-3 h-3 text-secondary" />
                    <div>
                        <p className="text-[8px] text-muted-foreground">{renderParsedText(parseText(config.strings.serverStatus))}</p>
                        <motion.p className="text-[8px] font-semibold text-primary" whileHover={{ scale: 1.05 }}>
                            {renderParsedText(parseText(serverStatus))}
                        </motion.p>
                    </div>
                </motion.div>
                <motion.div className="flex items-center gap-1 hover:scale-105 transition-transform" whileHover={{ scale: 1.05 }}>
                    <Zap className="w-3 h-3 text-primary" />
                    <div>
                        <p className="text-[8px] text-muted-foreground">{renderParsedText(parseText(config.strings.ping))}</p>
                        <p className="text-[8px] font-semibold text-foreground">
                            <AnimatedNumber value={avgPing} isMini={isMini} />ms
                        </p>
                    </div>
                </motion.div>
            </motion.div>
        )
    }
}

export default ServerInfoCards