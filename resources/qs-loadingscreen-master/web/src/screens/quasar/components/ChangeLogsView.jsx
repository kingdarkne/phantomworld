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

const ChangeLogsView = ({ config, goBack }) => {
    const [searchQuery, setSearchQuery] = useState("")

    const filteredChangeLogs = config.changeLogs
        .map((log, index) => ({
            ...log,
            index,
            matches: stripTags(log.title).toLowerCase().includes(searchQuery.toLowerCase()) ||
                     stripTags(log.content).toLowerCase().includes(searchQuery.toLowerCase())
        }))
        .filter((log) => log.matches)

    return (
        <motion.div
            className="grid grid-cols-1 md:grid-cols-4 gap-8 w-full max-w-5xl mx-auto p-8"
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
                        Index
                    </motion.h3>
                    <motion.ul className="space-y-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2 }}>
                        {config.changeLogs.map((log, index) => (
                            <motion.li 
                                key={index}
                                whileHover={{ x: 4 }}
                                className="cursor-pointer"
                            >
                                <a href={`#log-${index}`} className="text-primary hover:underline">
                                    {renderParsedText(parseText(log.title))}
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
                        <motion.h2 className="text-2xl font-bold text-foreground">Change Logs</motion.h2>
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
                            placeholder="Search change logs..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="pl-10"
                        />
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                    </motion.div>
                    <ScrollArea className="h-[60vh]">
                        <motion.div className="space-y-8" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.3 }}>
                            {filteredChangeLogs.map((log) => (
                                <motion.div 
                                    key={log.index} 
                                    id={`log-${log.index}`}
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
                                        {renderParsedText(parseText(log.title))}
                                    </motion.h3>
                                    <motion.p 
                                        className="text-sm text-muted-foreground mb-2"
                                        initial={{ opacity: 0 }}
                                        whileInView={{ opacity: 1 }}
                                        viewport={{ once: true }}
                                        transition={{ delay: 0.1 }}
                                    >
                                        {renderParsedText(parseText(log.date))}
                                    </motion.p>
                                    <motion.p 
                                        className="text-muted-foreground mb-4"
                                        initial={{ opacity: 0 }}
                                        whileInView={{ opacity: 1 }}
                                        viewport={{ once: true }}
                                        transition={{ delay: 0.1 }}
                                    >
                                        {renderParsedText(parseText(log.content))}
                                    </motion.p>
                                    {log.images && log.images.length > 0 && (
                                        <motion.div 
                                            className="grid grid-cols-1 md:grid-cols-3 gap-4"
                                            initial={{ opacity: 0, scale: 0.9 }}
                                            whileInView={{ opacity: 1, scale: 1 }}
                                            viewport={{ once: true }}
                                            transition={{ delay: 0.2 }}
                                        >
                                            {log.images.map((image, imgIndex) => (
                                                <motion.img
                                                    key={imgIndex}
                                                    src={image}
                                                    alt={`Change log image ${imgIndex + 1}`}
                                                    className="rounded-lg shadow-md w-full h-auto"
                                                    initial={{ opacity: 0, y: 20 }}
                                                    whileInView={{ opacity: 1, y: 0 }}
                                                    viewport={{ once: true }}
                                                    transition={{ duration: 0.5, delay: imgIndex * 0.1 }}
                                                    whileHover={{ scale: 1.05 }}
                                                />
                                            ))}
                                        </motion.div>
                                    )}
                                </motion.div>
                            ))}
                            {filteredChangeLogs.length === 0 && (
                                <motion.p 
                                    className="text-muted-foreground text-center"
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                >
                                    No change logs found matching your search.
                                </motion.p>
                            )}
                        </motion.div>
                    </ScrollArea>
                </Card>
            </motion.div>
        </motion.div>
    )
}

export default ChangeLogsView