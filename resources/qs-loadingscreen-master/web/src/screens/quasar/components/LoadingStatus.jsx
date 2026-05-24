import { motion } from "motion/react"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Zap, Shield, Loader2, MapPin, Users } from "lucide-react"
import { parseText } from "@/lib/utils"

const iconMap = {
    Zap: Zap,
    Shield: Shield,
    Loader2: Loader2,
    MapPin: MapPin,
    Users: Users,
}

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

const LoadingStatus = ({ config, title, progress, currentPhase, loadingStats }) => {
    const getPhaseIcon = () => {
        const IconComponent = iconMap[config.loadingPhases[currentPhase]?.icon || config.loadingPhases.default.icon]
        return <IconComponent className="w-5 h-5" />
    }

    const getPhaseLabel = () => {
        return config.loadingPhases[currentPhase]?.label || config.loadingPhases.default.label
    }

    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
        >
            <Card className="bg-card/80 backdrop-blur-sm border-border/50 p-8 mb-8">
                <div className="flex items-center gap-4 mb-6">
                    <motion.div
                        className="p-3 bg-primary/10 rounded-lg border border-primary/20"
                        whileHover={{ scale: 1.05 }}
                    >
                        {getPhaseIcon()}
                    </motion.div>
                    <div className="flex-1">
                        <motion.div
                            className="flex items-center gap-3 mb-2"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ delay: 0.2 }}
                        >
                            <Badge variant="outline" className="border-primary/30 text-primary">
                                {renderParsedText(parseText(getPhaseLabel()))}
                            </Badge>
                            <motion.span
                                className="text-sm text-muted-foreground"
                                initial={{ scale: 0.8 }}
                                animate={{ scale: 1 }}
                            >
                                {Math.round(progress)}%
                            </motion.span>
                        </motion.div>
                        <motion.h3
                            className="text-lg font-semibold text-foreground text-balance"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            transition={{ delay: 0.4 }}
                        >
                            {renderParsedText(parseText(title))}
                        </motion.h3>
                    </div>
                </div>
                <motion.div className="space-y-3" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.6 }}>
                    <Progress value={progress} className="h-3 bg-muted/50" />
                    <motion.div
                        className="flex justify-between text-sm text-muted-foreground"
                        initial={{ x: -10 }}
                        animate={{ x: 0 }}
                        transition={{ delay: 0.8 }}
                    >
                        <span>{renderParsedText(parseText(config.strings.loadingResources))}</span>
                        <span>{renderParsedText(parseText(config.strings.filesProcessed.replace("{count}", loadingStats.filesLoaded)))}</span>
                    </motion.div>
                </motion.div>
            </Card>
        </motion.div>
    )
}

export default LoadingStatus