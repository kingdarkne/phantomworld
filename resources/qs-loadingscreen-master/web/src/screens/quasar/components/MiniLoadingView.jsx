import { motion } from "motion/react"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import ServerBranding from "./ServerBranding"
import ServerInfoCards from "./ServerInfoCards"
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

const MiniLoadingView = ({ config, title, progress, currentPhase, playerCount, maxPlayers, avgPing, serverStatus }) => {
    const getPhaseLabel = () => {
        return config.loadingPhases[currentPhase]?.label || config.loadingPhases.default.label
    }

    return (
        <motion.div 
            className="fixed bottom-0 w-full p-2 bg-background/80 backdrop-blur-sm border-t border-border"
            initial={{ y: 100 }}
            animate={{ y: 0 }}
            transition={{ duration: 0.5 }}
        >
            <div className="w-[70%] mx-auto flex items-center justify-between gap-2">
                <motion.div 
                    className="flex items-center gap-2"
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.2 }}
                >
                    <ServerBranding isMini config={config} />
                    <div>
                        <motion.div 
                            className="flex items-center gap-1"
                            initial={{ scale: 0.8 }}
                            animate={{ scale: 1 }}
                        >
                            <Badge variant="outline" className="border-primary/30 text-primary text-[8px] px-1 py-0">
                                {renderParsedText(parseText(getPhaseLabel()))}
                            </Badge>
                            <span className="text-muted-foreground text-[8px]">{Math.round(progress)}%</span>
                        </motion.div>
                        <motion.p 
                            className="text-sm font-bold text-foreground mt-1"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ delay: 0.2 }}
                        >
                            {renderParsedText(parseText(title))}
                        </motion.p>
                    </div>
                </motion.div>
                <motion.div 
                    className="flex-1"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ delay: 0.4 }}
                >
                    <Progress value={progress} className="h-1 bg-muted/50 w-full" />
                </motion.div>
                <motion.div 
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 }}
                >
                    <ServerInfoCards 
                        config={config}
                        playerCount={playerCount} 
                        maxPlayers={maxPlayers} 
                        avgPing={avgPing} 
                        serverStatus={serverStatus} 
                        isMini 
                    />
                </motion.div>
            </div>
        </motion.div>
    )
}

export default MiniLoadingView