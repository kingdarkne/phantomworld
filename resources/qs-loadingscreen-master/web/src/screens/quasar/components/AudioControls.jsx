import { Slider } from "@/components/ui/slider"
import { Volume2, VolumeX, Play, Pause, Music } from "lucide-react"
import { Button } from "@/components/ui/button"

const AudioControls = ({ volume, setVolume, playerRef, isPlaying, setIsPlaying, toggleAudioSource, audioSource, isMuted, setIsMuted }) => {
    //TODO: make a working togglePlay
    // const togglePlay = () => {
    //     if (playerRef.current) {
    //         if (isPlaying) {
    //             console.log(`Pausing ${audioSource} playback`)
    //             playerRef.current.getInternalPlayer()?.pause?.()
    //             setIsPlaying(false)
    //         } else {
    //             console.log(`Starting ${audioSource} playback`)
    //             const playPromise = playerRef.current.getInternalPlayer()?.play?.()
    //             if (playPromise) {
    //                 playPromise.then(() => {
    //                     setIsPlaying(true)
    //                 }).catch((e) => {
    //                     console.error(`${audioSource} play failed:`, e)
    //                 })
    //             }
    //         }
    //     }
    // }

    const toggleMute = () => {
        const newMuted = !isMuted
        // console.log(`Toggling mute for ${audioSource}: ${newMuted}`)
        setIsMuted(newMuted)
        if (playerRef.current) {
            playerRef.current.getInternalPlayer().muted = newMuted
            if (!newMuted) {
                setVolume(audioSource === "video" ? 0.5 : 0.15) // Restore default volume
            }
        }
    }

    const handleVolumeChange = (newVolume) => {
        const volumeValue = newVolume[0]
        // console.log(`Setting ${audioSource} volume to: ${volumeValue}`)
        setVolume(volumeValue)
        // if (playerRef.current) {
        //     playerRef.current.getInternalPlayer().volume = volumeValue
        // }
    }

    return (
        <div className="absolute bottom-4 left-4 z-20 flex items-center gap-2 bg-card/80 p-2 rounded-lg backdrop-blur-sm border border-border/50">
            {/* <Button variant="ghost" size="icon" onClick={togglePlay} className="h-8 w-8">
                {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            </Button> */}
            <Button variant="ghost" size="icon" onClick={toggleMute} className="h-8 w-8">
                {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
            </Button>
            <Slider
                value={[volume]}
                onValueChange={handleVolumeChange}
                max={1}
                min={0}
                step={0.01}
                className="w-24 h-2"
            />
            <Button variant="ghost" size="icon" onClick={toggleAudioSource} className="h-8 w-8">
                <Music className="w-4 h-4" />
                <span className="sr-only">{audioSource === "video" ? "Switch to MP3" : "Switch to Video Audio"}</span>
            </Button>
        </div>
    )
}

export default AudioControls