import { useState } from "react"
import { motion } from "motion/react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Search } from "lucide-react"
import { ScrollArea } from "@/components/ui/scroll-area"
import { parseText, stripTags } from "@/lib/utils"

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

const KeybindsView = ({ goBack, config }) => {
    const [searchQuery, setSearchQuery] = useState("")
    const [hoveredKey, setHoveredKey] = useState(null)

    const filteredKeybinds = config.keybinds
        .map((keybind, index) => ({
            ...keybind,
            index,
            matches:
                stripTags(keybind.key).toLowerCase().includes(searchQuery.toLowerCase()) ||
                stripTags(keybind.title).toLowerCase().includes(searchQuery.toLowerCase()) ||
                stripTags(keybind.description).toLowerCase().includes(searchQuery.toLowerCase())
        }))
        .filter((keybind) => keybind.matches)

    // Define a simple keyboard layout (subset of keys for simplicity)
    const keyboardLayout = [
        ['Escape', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12'],
        ['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 'Backspace'],
        ['Tab', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '[', ']', '\\'],
        ['CapsLock', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ';', '\'', 'Enter'],
        ['Shift', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', ',', '.', '/', 'Shift'],
        ['Ctrl', 'Alt', 'Space', 'Alt', 'Ctrl']
    ]

    return (
        <motion.div
            className="grid grid-cols-1 md:grid-cols-4 gap-8 w-full max-w-7xl mx-auto p-8"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5 }}
        >
            <motion.div 
                className="md:col-span-1 sticky top-8 self-start max-h-[calc(100vh-4rem)] overflow-y-auto scrollbar-thin scrollbar-track-background scrollbar-thumb-primary"
                initial={{ x: -20 }}
                animate={{ x: 0 }}
                transition={{ delay: 0.2 }}
            >
                <Card className="bg-card/70 backdrop-blur-sm border-border/50 p-4">
                    <motion.h3 
                        className="text-lg font-semibold text-foreground mb-4"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                    >
                        Keybinds Index
                    </motion.h3>
                    <motion.ul className="space-y-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }}>
                        {filteredKeybinds.map((keybind) => (
                            <motion.li 
                                key={keybind.index}
                                whileHover={{ x: 4 }}
                                className="cursor-pointer"
                            >
                                <a href={`#keybind-${keybind.index}`} className="text-primary hover:underline">
                                    {renderParsedText(parseText(keybind.title))}
                                </a>
                            </motion.li>
                        ))}
                    </motion.ul>
                </Card>
            </motion.div>
            <motion.div className="md:col-span-3" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }}>
                <Card className="bg-card/70 backdrop-blur-sm border-border/50 p-8">
                    <motion.div 
                        className="flex items-center justify-between mb-6"
                        initial={{ opacity: 0, y: -20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: 0.1 }}
                    >
                        <motion.h2 className="text-2xl font-bold text-foreground">Keybinds</motion.h2>
                        <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                            <Button onClick={goBack} variant="outline">
                                Back to Loading
                            </Button>
                        </motion.div>
                    </motion.div>
                    <motion.div 
                        className="relative mb-6"
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        transition={{ delay: 0.2 }}
                    >
                        <Input
                            type="text"
                            placeholder="Search keybinds..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-10"
                        />
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    </motion.div>
                    <div className="mb-8">
                        <div className="bg-card/90 p-6 rounded-lg border border-border/50 shadow-md">
                            {keyboardLayout.map((row, rowIndex) => (
                                <div key={rowIndex} className="flex gap-1 mb-1 justify-center">
                                    {row.map((key) => {
                                        const keybind = config.keybinds.find(k => stripTags(k.key).toLowerCase() === key.toLowerCase())
                                        return (
                                            <motion.div
                                                key={key}
                                                className={`relative text-foreground text-sm font-semibold rounded-md flex items-center justify-center border transition-colors shadow-sm ${
                                                    keybind ? 'bg-primary/10 border-primary/50' : 'bg-background/80 border-border/30'
                                                }`}
                                                style={{
                                                    width: key === 'Space' ? '180px' : key === 'Escape' ? '80px' : key === 'Backspace' || key === 'Tab' || key === 'CapsLock' || key === 'Enter' || key === 'Shift' ? '90px' : key === 'Ctrl' || key === 'Alt' ? '70px' : '44px',
                                                    height: '44px'
                                                }}
                                                whileHover={{ scale: 1.05, backgroundColor: 'rgba(59, 130, 246, 0.2)', borderColor: 'rgba(59, 130, 246, 0.5)' }}
                                                onHoverStart={() => setHoveredKey(key.toLowerCase())}
                                                onHoverEnd={() => setHoveredKey(null)}
                                            >
                                                {key}
                                                {keybind && hoveredKey === key.toLowerCase() && (
                                                    <motion.div
                                                        className="absolute z-20 bg-card/95 backdrop-blur-md border border-border/50 p-4 rounded-lg shadow-lg -top-28 left-1/2 transform -translate-x-1/2 w-72 text-center"
                                                        initial={{ opacity: 0, y: 10 }}
                                                        animate={{ opacity: 1, y: 0 }}
                                                        transition={{ duration: 0.2 }}
                                                    >
                                                        <h4 className="font-semibold text-foreground mb-2">
                                                            {renderParsedText(parseText(keybind.title))}
                                                        </h4>
                                                        <p className="text-sm text-muted-foreground">
                                                            {renderParsedText(parseText(keybind.description))}
                                                        </p>
                                                    </motion.div>
                                                )}
                                            </motion.div>
                                        )
                                    })}
                                </div>
                            ))}
                        </div>
                    </div>
                    <ScrollArea className="h-[20vh]">
                        <motion.div className="space-y-8" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.3 }}>
                            {filteredKeybinds.map((keybind) => (
                                <motion.div 
                                    key={keybind.index} 
                                    id={`keybind-${keybind.index}`}
                                    initial={{ opacity: 0, y: 20 }}
                                    whileInView={{ opacity: 1, y: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ duration: 0.6 }}
                                >
                                    <motion.h3 
                                        className="text-xl font-bold text-foreground mb-2"
                                        initial={{ opacity: 0 }}
                                        whileInView={{ opacity: 1 }}
                                        viewport={{ once: true }}
                                    >
                                        {renderParsedText(parseText(keybind.title))}
                                    </motion.h3>
                                    <motion.p 
                                        className="text-sm text-muted-foreground mb-2"
                                        initial={{ opacity: 0 }}
                                        whileInView={{ opacity: 1 }}
                                        viewport={{ once: true }}
                                        transition={{ delay: 0.1 }}
                                    >
                                        Key: <span className="text-primary">{renderParsedText(parseText(keybind.key))}</span>
                                    </motion.p>
                                    <motion.p 
                                        className="text-muted-foreground"
                                        initial={{ opacity: 0 }}
                                        whileInView={{ opacity: 1 }}
                                        viewport={{ once: true }}
                                        transition={{ delay: 0.1 }}
                                    >
                                        {renderParsedText(parseText(keybind.description))}
                                    </motion.p>
                                </motion.div>
                            ))}
                            {filteredKeybinds.length === 0 && (
                                <motion.p 
                                    className="text-muted-foreground text-center"
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                >
                                    No keybinds found matching your search.
                                </motion.p>
                            )}
                        </motion.div>
                    </ScrollArea>
                </Card>
            </motion.div>
        </motion.div>
    )
}

export default KeybindsView