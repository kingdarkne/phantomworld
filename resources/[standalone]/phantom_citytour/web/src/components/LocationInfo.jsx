import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { MapPin, Clock, Info, ChevronRight, ChevronLeft, SkipForward, Pause, Play, Navigation } from 'lucide-react'

export function LocationInfo({ location, onSetWaypoint, onNext, onPrevious, onSkip, isPaused }) {
  const [showDetails, setShowDetails] = useState(false)
  const [currentFactIndex, setCurrentFactIndex] = useState(0)

  useEffect(() => {
    setCurrentFactIndex(0)
  }, [location])

  const nextFact = () => {
    if (location?.info?.facts) {
      setCurrentFactIndex((prev) => (prev + 1) % location.info.facts.length)
    }
  }

  const prevFact = () => {
    if (location?.info?.facts) {
      setCurrentFactIndex((prev) => (prev - 1 + location.info.facts.length) % location.info.facts.length)
    }
  }

  if (!location) return null

  return (
    <motion.div
      initial={{ x: -100, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      exit={{ x: -100, opacity: 0 }}
      className="fixed left-8 top-1/2 -translate-y-1/2 w-96 pointer-events-auto z-40"
    >
      <div className="glass rounded-2xl p-6 space-y-4">
        {/* Location Header */}
        <div className="space-y-3">
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="flex items-center space-x-3"
          >
            <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
              <MapPin className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white">{location.name}</h2>
              <p className="text-white/70 text-sm">{location.description}</p>
            </div>
          </motion.div>
        </div>

        {/* Information Panel */}
        <AnimatePresence mode="wait">
          {!showDetails ? (
            <motion.div
              key="summary"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="space-y-4"
            >
              {/* Title and Subtitle */}
              <div className="space-y-2">
                <h3 className="text-xl font-semibold text-gradient">{location.info.title}</h3>
                <p className="text-white/80">{location.info.subtitle}</p>
              </div>

              {/* Description */}
              <p className="text-white/70 leading-relaxed">{location.info.description}</p>

              {/* Facts Carousel */}
              {location.info.facts && location.info.facts.length > 0 && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="text-sm font-semibold text-white/60 uppercase tracking-wider">Key Features</h4>
                    <div className="flex space-x-1">
                      <button
                        onClick={prevFact}
                        className="p-1 rounded hover:bg-white/10 transition-colors"
                      >
                        <ChevronLeft className="w-4 h-4 text-white/60" />
                      </button>
                      <button
                        onClick={nextFact}
                        className="p-1 rounded hover:bg-white/10 transition-colors"
                      >
                        <ChevronRight className="w-4 h-4 text-white/60" />
                      </button>
                    </div>
                  </div>
                  
                  <motion.div
                    key={currentFactIndex}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    className="bg-white/5 rounded-lg p-3 border border-white/10"
                  >
                    <p className="text-white/80">{location.info.facts[currentFactIndex]}</p>
                  </motion.div>
                  
                  {/* Fact Indicators */}
                  <div className="flex space-x-1 justify-center">
                    {location.info.facts.map((_, index) => (
                      <div
                        key={index}
                        className={`w-2 h-2 rounded-full transition-all ${
                          index === currentFactIndex
                            ? 'bg-purple-500 w-6'
                            : 'bg-white/30'
                        }`}
                      />
                    ))}
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex space-x-3">
                <button
                  onClick={() => location.info.waypoint && onSetWaypoint(location.info.waypoint)}
                  disabled={!location.info.waypoint}
                  className="flex-1 btn-secondary flex items-center justify-center space-x-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Navigation className="w-4 h-4" />
                  <span>Set Waypoint</span>
                </button>
                <button
                  onClick={() => setShowDetails(true)}
                  className="flex-1 btn-primary flex items-center justify-center space-x-2"
                >
                  <Info className="w-4 h-4" />
                  <span>Details</span>
                </button>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="details"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="space-y-4"
            >
              {/* Detailed Information */}
              <div className="space-y-3">
                <h4 className="text-lg font-semibold text-gradient">Detailed Information</h4>
                
                {/* All Facts */}
                {location.info.facts && (
                  <div className="space-y-2">
                    <h5 className="text-sm font-semibold text-white/60 uppercase tracking-wider">All Features</h5>
                    <div className="space-y-2">
                      {location.info.facts.map((fact, index) => (
                        <motion.div
                          key={index}
                          initial={{ opacity: 0, x: -20 }}
                          animate={{ opacity: 1, x: 0 }}
                          transition={{ delay: index * 0.1 }}
                          className="flex items-start space-x-2"
                        >
                          <div className="w-2 h-2 bg-purple-500 rounded-full mt-2 flex-shrink-0" />
                          <p className="text-white/80 text-sm">{fact}</p>
                        </motion.div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Back Button */}
              <button
                onClick={() => setShowDetails(false)}
                className="w-full btn-secondary"
              >
                Back to Summary
              </button>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Tour Controls */}
        <div className="flex space-x-2 pt-4 border-t border-white/10">
          <button
            onClick={onPrevious}
            className="flex-1 p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors flex items-center justify-center"
            title="Previous Location"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          
          <button
            onClick={onSkip}
            className="flex-1 p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors flex items-center justify-center"
            title="Skip Location"
          >
            <SkipForward className="w-4 h-4" />
          </button>
          
          <button
            onClick={isPaused ? onNext : undefined}
            className="flex-1 p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors flex items-center justify-center"
            title={isPaused ? "Next Location" : "Auto-advance enabled"}
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </motion.div>
  )
}
