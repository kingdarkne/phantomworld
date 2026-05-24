import { motion } from "motion/react"
import ServerBranding from "./ServerBranding"
import LoadingStatus from "./LoadingStatus"
import ServerInfoCards from "./ServerInfoCards"
import LoadingTips from "./LoadingTips"
import ActionButtons from "./ActionButtons"

const MainLoadingView = ({
    config,
    title,
    progress,
    currentPhase,
    loadingStats,
    playerCount,
    maxPlayers,
    avgPing,
    serverStatus,
    currentTip,
    goToRules,
    goToChangeLogs,
    goToKeybinds
}) => {
    return (
        <motion.div
            className="w-full max-w-5xl mx-auto p-8 overflow-hidden h-screen"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5 }}
        >
            <ServerBranding config={config} />
            <LoadingStatus
                config={config}
                title={title}
                progress={progress}
                currentPhase={currentPhase}
                loadingStats={loadingStats}
            />
            <ServerInfoCards
                config={config}
                playerCount={playerCount}
                maxPlayers={maxPlayers}
                avgPing={avgPing}
                serverStatus={serverStatus}
            />
            <LoadingTips config={config} currentTip={currentTip} />
            <ActionButtons goToRules={goToRules} goToChangeLogs={goToChangeLogs} goToKeybinds={goToKeybinds} />
        </motion.div>
    )
}

export default MainLoadingView