import React from 'react'
import { motion } from 'framer-motion'
import { Play, Pause, Square, SkipForward, ChevronLeft, ChevronRight, BarChart3, Eye, EyeOff, X } from 'lucide-react'

export function TourControls({ 
  onStart, 
  onStop, 
  onPause, 
  onNext, 
  onPrevious, 
  onSkip, 
  isPaused, 
  onToggleStats,
  onToggleUI,
  currentLocation,
  totalLocations 
}) {
  return (
    <motion.div
      initial={{ y: 100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      exit={{ y: 100, opacity: 0 }}
      className="fixed bottom-8 left-1/2 -translate-x-1/2 pointer-events-auto z-40"
    >
      <div className="glass rounded-full px-6 py-4 flex items-center space-x-4">
        {/* Previous Location */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onPrevious}
          disabled={!currentLocation || currentLocation.currentIndex <= 1}
          className="p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          title="Previous Location"
        >
          <ChevronLeft className="w-5 h-5 text-white" />
        </motion.button>

        {/* Play/Pause */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onPause}
          className="p-3 rounded-full bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 transition-all"
          title={isPaused ? "Resume Tour" : "Pause Tour"}
        >
          {isPaused ? (
            <Play className="w-5 h-5 text-white" />
          ) : (
            <Pause className="w-5 h-5 text-white" />
          )}
        </motion.button>

        {/* Skip Location */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onSkip}
          disabled={!currentLocation || currentLocation.currentIndex >= totalLocations}
          className="p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          title="Skip Location"
        >
          <SkipForward className="w-5 h-5 text-white" />
        </motion.button>

        {/* Next Location */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onNext}
          disabled={!currentLocation || currentLocation.currentIndex >= totalLocations}
          className="p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          title="Next Location"
        >
          <ChevronRight className="w-5 h-5 text-white" />
        </motion.button>

        {/* Divider */}
        <div className="w-px h-8 bg-white/20" />

        {/* Stats */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onToggleStats}
          className="p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors"
          title="View Tour Statistics"
        >
          <BarChart3 className="w-5 h-5 text-white" />
        </motion.button>

        {/* Toggle UI */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onToggleUI}
          className="p-3 rounded-full bg-white/10 hover:bg-white/20 transition-colors"
          title="Hide/Show UI"
        >
          <EyeOff className="w-5 h-5 text-white" />
        </motion.button>

        {/* Stop Tour */}
        <motion.button
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
          onClick={onStop}
          className="p-3 rounded-full bg-red-500/20 hover:bg-red-500/30 transition-colors border border-red-500/50"
          title="End Tour"
        >
          <Square className="w-5 h-5 text-red-400" />
        </motion.button>
      </div>

      {/* Keyboard Shortcuts Hint */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="mt-4 text-center"
      >
        <p className="text-white/60 text-xs">
          Press <kbd className="px-2 py-1 bg-white/10 rounded">Space</kbd> to skip • 
          <kbd className="px-2 py-1 bg-white/10 rounded ml-2">P</kbd> to pause • 
          <kbd className="px-2 py-1 bg-white/10 rounded ml-2">H</kbd> to toggle UI • 
          <kbd className="px-2 py-1 bg-white/10 rounded ml-2">Esc</kbd> to exit
        </p>
      </motion.div>
    </motion.div>
  )
}
