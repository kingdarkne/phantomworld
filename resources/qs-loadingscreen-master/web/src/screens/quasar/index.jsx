"use client"
import { useState, useEffect, useRef } from "react"
import { motion } from "motion/react"
import ReactPlayer from "react-player"
import Particles from "./components/Particles"
import MainLoadingView from "./components/MainLoadingView"
import MiniLoadingView from "./components/MiniLoadingView"
import RulesView from "./components/RulesView"
import ChangeLogsView from "./components/ChangeLogsView"
import KeybindsView from "./components/KeybindsView"
import AudioControls from "./components/AudioControls"
import { Loader } from "lucide-react"

export default function QuasarLoadingScreen() {
    const [config, setConfig] = useState(null)
    const [title, setTitle] = useState("Initializing FiveM...")
    const [progress, setProgress] = useState(0)
    const [currentPhase, setCurrentPhase] = useState("startup")
    const [loadingStats, setLoadingStats] = useState({
        filesLoaded: 0,
        totalFiles: 0,
        currentFile: "",
    })
    const [playerCount, setPlayerCount] = useState(0)
    const [maxPlayers, setMaxPlayers] = useState(0)
    const [avgPing, setAvgPing] = useState(0)
    const [serverStatus, setServerStatus] = useState("OFFLINE")
    const [currentTip, setCurrentTip] = useState(null)
    const [view, setView] = useState("loading")
    const [videoReady, setVideoReady] = useState(false)
    const [playing, setPlaying] = useState(true)
    const [videoMuted, setVideoMuted] = useState(true) // Start muted to avoid autoplay issues
    const [musicMuted, setMusicMuted] = useState(false) // Inverse of video muted
    const [volume, setVolume] = useState(0.5)
    const videoRef = useRef(null)
    const audioRef = useRef(null)

    useEffect(() => {
        fetch('./config.json')
            .then((res) => {
                if (!res.ok) {
                    throw new Error('Failed to load config.json')
                }
                return res.json()
            })
            .then((data) => {
                // console.log('Config loaded:', data); // Log the config
                // console.log('Video URL:', data.background?.videoUrl); // Log the video URL
                // console.log('Video URL:', data.background?.videoUrl); // Log the video URL
                setConfig(data);
                setCurrentTip(data.proTips[0]);
                setVideoMuted(!data.audio.useVideoAudio);
                setMusicMuted(data.audio.useVideoAudio);
                setVolume(data.audio.volume);
            })
            .catch((err) => {
                console.error("Error loading config.json:", err);
            });
    }, []);

    const isVideoBackground = config?.background?.type === "video" && config?.background?.videoUrl

    function setProgressValue(value) {
        if (value > 100) value = value / 10
        if (value < 0) value = 0
        setProgress(Math.min(100, value))
    }

    useEffect(() => {
        if (!config) return

        const fetchServerData = () => {
            fetch(`https://servers-frontend.fivem.net/api/servers/single/${config.server.serverId}`)
                .then((res) => res.json())
                .then((data) => {
                    if (data.error) {
                        console.error('Failed to fetch server details, provide a valid config serverId...')
                        setServerStatus("OFFLINE")
                        setPlayerCount(0)
                        setMaxPlayers(0)
                        setAvgPing(0)
                    } else {
                        const serverData = data.Data
                        setPlayerCount(serverData.clients || 0)
                        setMaxPlayers(serverData.sv_maxclients || 0)
                        const pings = serverData.players?.map((p) => p.ping) || []
                        const avg = pings.length > 0 ? Math.round(pings.reduce((a, b) => a + b, 0) / pings.length) : 0
                        setAvgPing(avg)
                        setServerStatus("ONLINE")
                    }
                })
                .catch((err) => {
                    console.error("Error fetching server data:", err)
                    setServerStatus("OFFLINE")
                    setPlayerCount(0)
                    setMaxPlayers(0)
                    setAvgPing(0)
                })
        }

        fetchServerData()
        const interval = setInterval(fetchServerData, 5000)
        return () => clearInterval(interval)
    }, [config])

    useEffect(() => {
        if (!config) return

        const tipInterval = setInterval(() => {
            setCurrentTip(config.proTips[Math.floor(Math.random() * config.proTips.length)])
        }, 5000)
        return () => clearInterval(tipInterval)
    }, [config])

    useEffect(() => {
        if (progress === 100) {
            // console.log("Progress reached 100%, fading out video audio")
            const fadeOut = () => {
                let currentVolume = volume
                const fadeInterval = setInterval(() => {
                    currentVolume -= 0.01
                    if (currentVolume <= 0) {
                        clearInterval(fadeInterval)
                        setPlaying(false)
                    } else {
                        setVolume(currentVolume)
                    }
                }, 100)
            }
            fadeOut()
        }
    }, [progress])

    useEffect(() => {
        if (isVideoBackground && videoReady && !playing) {
            // console.log("Attempting to play video")
            setPlaying(true)
        }
        if (videoReady && isVideoBackground && playing) {
            videoRef.current.currentTime = config?.background?.startFrom || 0
        }
    }, [videoReady, isVideoBackground, playing])

    useEffect(() => {
        const handlers = {
            initFunctionInvoking(data) {
                setTitle(`Loading System: ${data.name}`)
                setCurrentPhase("systems")
                setLoadingStats((prev) => ({ ...prev, currentFile: data.name || "" }))
            },

            onDataFileEntry(data) {
                setTitle(`Loading Asset: ${data.name}`)
                setCurrentPhase("assets")
                setLoadingStats((prev) => ({
                    ...prev,
                    filesLoaded: prev.filesLoaded + 1,
                    currentFile: data.name || "",
                }))
            },

            performMapLoadFunction(data) {
                setTitle(`Loading Map Components`)
                setCurrentPhase("map")
            },

            loadProgress(data) {
                const progressValue = (data.loadFraction || 0) * 100
                setProgressValue(progressValue)

                if (progressValue < 25) setCurrentPhase("startup")
                else if (progressValue < 50) setCurrentPhase("systems")
                else if (progressValue < 75) setCurrentPhase("assets")
                else if (progressValue < 95) setCurrentPhase("map")
                else setCurrentPhase("finalizing")
            },

            onLogLine(data) {
                setTitle(data.message || "Loading...")
            },
        }

        const messageHandler = (e) => {
            const handler = handlers[e.data.eventName]
            if (handler) {
                handler(e.data)
            }
        }

        window.addEventListener("message", messageHandler)

        return () => {
            window.removeEventListener("message", messageHandler)
        }
    }, [])

    const handleVideoReady = () => {
        // console.log("Video is ready")
        setVideoReady(true)
    }

    const handleVideoError = (error) => {
        console.error("Video error:", error)
        setVideoReady(false)
        setPlaying(false)
    }

    const goToRules = () => setView("rules")
    const goToChangeLogs = () => setView("changelogs")
    const goToKeybinds = () => setView("keybinds")
    const goBack = () => setView("loading")

    if (!config) {
        return (
            <div className="min-h-screen bg-background relative overflow-hidden flex items-center justify-center">
                <div className="min-h-screen bg-background flex items-center justify-center">
                    <div className="text-center">
                        <Loader className="w-12 h-12 text-primary animate-spin mb-4" />
                        <div className="text-white text-xl font-bold mb-2">Loading Screen</div>
                        <div className="text-gray-300 text-sm">Please wait...</div>
                    </div>
                </div>
            </div>
        )
    }

    return (
        <div className="min-h-screen bg-background relative overflow-hidden flex items-center justify-center">
            <Particles config={config} />
            {config.gridOverlay.enabled && (
                <div
                    className="absolute inset-0"
                    style={{
                        opacity: config.gridOverlay.opacity,
                        backgroundImage: `
                            linear-gradient(${config.gridOverlay.color} 1px, transparent 1px),
                            linear-gradient(90deg, ${config.gridOverlay.color} 1px, transparent 1px)
                        `,
                        backgroundSize: `${config.gridOverlay.size}px ${config.gridOverlay.size}px`,
                    }}
                />
            )}
            {config.blobs.map((blob, index) => (
                <div key={index} className={`absolute ${blob.position} ${blob.size} ${blob.color} rounded-full ${blob.blur}`} />
            ))}
            {isVideoBackground && (
                <motion.div
                    className="absolute inset-0 z-0"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: videoReady ? 1 : 0 }}
                    transition={{ duration: 1 }}
                >
                    <ReactPlayer
                        ref={videoRef}
                        src={config.background.videoUrl}
                        playing={playing}
                        loop={config.background.loop}
                        muted={videoMuted}
                        volume={volume}
                        width="100%"
                        height="100%"
                        style={{ position: 'absolute', top: 0, left: 0, objectFit: 'cover' }}
                        onReady={(...data) => {
                            // console.log(...data)
                            handleVideoReady(...data)
                        }}
                        onPlay={() => {
                            handleVideoReady()
                        }}
                        onError={handleVideoError}
                        config={{
                            youtube: {
                                playerVars: {
                                    controls: 0,
                                    showinfo: 0,
                                    rel: 0,
                                    modestbranding: 1,
                                    autoplay: 1
                                }
                            },
                            file: {
                                attributes: {
                                    preload: 'auto'
                                }
                            }
                        }}
                    />
                </motion.div>
            )}
            {config.audio.url && !config.audio.useVideoAudio && (
                <ReactPlayer
                    ref={audioRef}
                    src={config.audio.url}
                    playing={!musicMuted && playing}
                    loop={config.audio.loop}
                    volume={volume}
                    style={{ display: 'none' }}
                    config={{
                        youtube: {
                            playerVars: {
                                controls: 0,
                                showinfo: 0,
                                rel: 0,
                                modestbranding: 1,
                                autoplay: 1
                            }
                        },
                        file: {
                            attributes: {
                                preload: 'auto'
                            }
                        }
                    }}
                />
            )}

            <div className="relative z-10 w-full">
                {view === "loading" ? (
                    <MainLoadingView
                        config={config}
                        title={title}
                        progress={progress}
                        currentPhase={currentPhase}
                        loadingStats={loadingStats}
                        playerCount={playerCount}
                        maxPlayers={maxPlayers}
                        avgPing={avgPing}
                        serverStatus={serverStatus}
                        currentTip={currentTip}
                        goToRules={goToRules}
                        goToChangeLogs={goToChangeLogs}
                        goToKeybinds={goToKeybinds}
                    />
                ) : view === "rules" ? (
                    <>
                        <RulesView goBack={goBack} config={config} />
                        <MiniLoadingView
                            config={config}
                            title={title}
                            progress={progress}
                            currentPhase={currentPhase}
                            playerCount={playerCount}
                            maxPlayers={maxPlayers}
                            avgPing={avgPing}
                            serverStatus={serverStatus}
                        />
                    </>
                ) : view === "changelogs" ? (
                    <>
                        <ChangeLogsView goBack={goBack} config={config} />
                        <MiniLoadingView
                            config={config}
                            title={title}
                            progress={progress}
                            currentPhase={currentPhase}
                            playerCount={playerCount}
                            maxPlayers={maxPlayers}
                            avgPing={avgPing}
                            serverStatus={serverStatus}
                        />
                    </>
                ) : view === "keybinds" ? (
                    <>
                        <KeybindsView goBack={goBack} config={config} />
                        <MiniLoadingView
                            config={config}
                            title={title}
                            progress={progress}
                            currentPhase={currentPhase}
                            playerCount={playerCount}
                            maxPlayers={maxPlayers}
                            avgPing={avgPing}
                            serverStatus={serverStatus}
                        />
                    </>
                ) : null}
            </div>
            {isVideoBackground && videoReady && !config?.audio?.useVideoAudio && (
                <>
                    <AudioControls
                        volume={volume}
                        setVolume={setVolume}
                        playerRef={audioRef}
                        isPlaying={playing}
                        setIsPlaying={setPlaying}
                        isMuted={musicMuted}
                        setIsMuted={setMusicMuted}
                    />
                </>
            )}
            {isVideoBackground && videoReady && config?.audio?.useVideoAudio && (
                <>
                    <AudioControls
                        volume={volume}
                        setVolume={setVolume}
                        playerRef={videoRef}
                        isPlaying={playing}
                        setIsPlaying={setPlaying}
                        isMuted={videoMuted}
                        setIsMuted={setVideoMuted}
                    />
                </>
            )}
        </div>
    )
}