import { motion } from "motion/react"
import { Button } from "@/components/ui/button"
import { BookOpen, Keyboard } from "lucide-react"

const ActionButtons = ({ goToRules, goToChangeLogs, goToKeybinds }) => {
    return (
        <motion.div
            className="mt-8 flex justify-center gap-4"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
        >
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button onClick={goToRules} className="flex items-center gap-2">
                    <BookOpen className="w-4 h-4" />
                    View Server Rules
                </Button>
            </motion.div>
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button onClick={goToChangeLogs} variant="outline" className="flex items-center gap-2">
                    <BookOpen className="w-4 h-4" />
                    View Change Logs
                </Button>
            </motion.div>
            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button onClick={goToKeybinds} variant="outline" className="flex items-center gap-2">
                    <Keyboard className="w-4 h-4" />
                    View Keybinds
                </Button>
            </motion.div>
        </motion.div>
    )
}

export default ActionButtons