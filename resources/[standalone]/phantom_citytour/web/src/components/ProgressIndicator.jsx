import React from 'react'
import { motion } from 'framer-motion'
import { MapPin, Clock, Pause } from 'lucide-react'

export function ProgressIndicator({ current, total, progress, isPaused }) {
  return (
    <motion.div
      initial={{ y: -100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      exit={{ y: -100, opacity: 0 }}
      className="fixed top-8 left-1/2 -translate-x-1/2 pointer-events-auto z-40"
    >
      <div className="glass rounded-full px-6 py-3 flex items-center space-x-4">
        {/* Location Counter */}
        <div className="flex items-center space-x-2">
          <MapPin className="w-4 h-4 text-purple-400" />
          <span className="text-white font-medium">
            {current} / {total}
          </span>
        </div>

        {/* Progress Bar */}
        <div className="w-32 h-2 bg-white/20 rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-gradient-to-r from-purple-500 to-blue-500"
            initial={{ width: 0 }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.5, ease: "easeOut" }}
          />
        </div>

        {/* Status */}
        <div className="flex items-center space-x-2">
          {isPaused ? (
            <>
              <Pause className="w-4 h-4 text-yellow-400" />
              <span className="text-yellow-400 text-sm font-medium">Paused</span>
            </>
          ) : (
            <>
              <Clock className="w-4 h-4 text-green-400" />
              <span className="text-green-400 text-sm font-medium">Active</span>
            </>
          )}
        </div>
      </div>
    </motion.div>
  )
}
