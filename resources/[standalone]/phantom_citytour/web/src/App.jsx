import React, { useState, useEffect, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { TourInterface } from './components/TourInterface'
import { WelcomeScreen } from './components/WelcomeScreen'
import { TourControls } from './components/TourControls'
import { LocationInfo } from './components/LocationInfo'
import { ProgressIndicator } from './components/ProgressIndicator'
import { TourStats } from './components/TourStats'

function App() {
  const [isVisible, setIsVisible] = useState(false)
  const [tourData, setTourData] = useState(null)
  const [currentLocation, setCurrentLocation] = useState(null)
  const [isPaused, setIsPaused] = useState(false)
  const [showWelcome, setShowWelcome] = useState(false)
  const [showStats, setShowStats] = useState(false)
  const [uiHidden, setUIHidden] = useState(false)
  const [screenEffect, setScreenEffect] = useState(null)

  // Handle NUI messages from FiveM
  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data
      
      switch (data.action) {
        case 'showTour':
          setIsVisible(true)
          setTourData(data.tourData)
          setCurrentLocation(data.currentLocation)
          setShowWelcome(true)
          setTimeout(() => setShowWelcome(false), 3000)
          break
          
        case 'hideTour':
          setIsVisible(false)
          setShowWelcome(false)
          setShowStats(false)
          break
          
        case 'updateLocation':
          setCurrentLocation(data.location)
          break
          
        case 'updateProgress':
          if (tourData) {
            setTourData(prev => ({
              ...prev,
              currentLocation: data.location
            }))
          }
          break
          
        case 'pauseTour':
          setIsPaused(data.isPaused)
          break
          
        case 'toggleUI':
          setUIHidden(prev => !prev)
          break
          
        case 'screenEffect':
          setScreenEffect(data.effect)
          setTimeout(() => setScreenEffect(null), data.duration * 1000)
          break
          
        case 'showStats':
          setShowStats(true)
          break
          
        case 'hideStats':
          setShowStats(false)
          break
      }
    }

    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [tourData])

  // Send messages back to FiveM
  const sendMessage = useCallback((action, data = {}) => {
    fetch(`https://phantom_citytour/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: JSON.stringify(data)
    })
  }, [])

  // Tour control functions
  const startTour = useCallback(() => {
    sendMessage('startTour')
  }, [sendMessage])

  const stopTour = useCallback(() => {
    sendMessage('stopTour')
  }, [sendMessage])

  const nextLocation = useCallback(() => {
    sendMessage('nextLocation')
  }, [sendMessage])

  const previousLocation = useCallback(() => {
    sendMessage('previousLocation')
  }, [sendMessage])

  const skipLocation = useCallback(() => {
    sendMessage('skipLocation')
  }, [sendMessage])

  const pauseTour = useCallback(() => {
    sendMessage('pauseTour')
  }, [sendMessage])

  const setWaypoint = useCallback((waypoint) => {
    sendMessage('setWaypoint', { waypoint })
  }, [sendMessage])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyPress = (e) => {
      if (!isVisible) return
      
      switch (e.key) {
        case 'Escape':
          stopTour()
          break
        case ' ':
          e.preventDefault()
          skipLocation()
          break
        case 'p':
        case 'P':
          pauseTour()
          break
        case 'h':
        case 'H':
          setUIHidden(prev => !prev)
          break
        case 'ArrowRight':
          nextLocation()
          break
        case 'ArrowLeft':
          previousLocation()
          break
      }
    }

    window.addEventListener('keydown', handleKeyPress)
    return () => window.removeEventListener('keydown', handleKeyPress)
  }, [isVisible, startTour, stopTour, nextLocation, previousLocation, skipLocation, pauseTour])

  if (!isVisible) {
    return null
  }

  return (
    <div className="fixed inset-0 pointer-events-none z-50">
      {/* Screen Effects */}
      <AnimatePresence>
        {screenEffect && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 pointer-events-none z-50"
          >
            {screenEffect === 'fade_in' && (
              <div className="w-full h-full bg-black animate-fadeIn" />
            )}
            {screenEffect === 'fade_out' && (
              <div className="w-full h-full bg-black animate-fadeOut" />
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Welcome Screen */}
      <AnimatePresence>
        {showWelcome && (
          <WelcomeScreen />
        )}
      </AnimatePresence>

      {/* Main Tour Interface */}
      <AnimatePresence>
        {isVisible && !uiHidden && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="pointer-events-auto"
          >
            {/* Tour Stats Modal */}
            <AnimatePresence>
              {showStats && (
                <TourStats onClose={() => setShowStats(false)} />
              )}
            </AnimatePresence>

            {/* Progress Indicator */}
            {tourData && (
              <ProgressIndicator
                current={currentLocation?.currentIndex || 1}
                total={tourData.totalLocations}
                progress={currentLocation?.progress || 0}
                isPaused={isPaused}
              />
            )}

            {/* Location Information */}
            {currentLocation && (
              <LocationInfo
                location={currentLocation}
                onSetWaypoint={setWaypoint}
                onNext={nextLocation}
                onPrevious={previousLocation}
                onSkip={skipLocation}
                isPaused={isPaused}
              />
            )}

            {/* Tour Controls */}
            <TourControls
              onStart={startTour}
              onStop={stopTour}
              onPause={pauseTour}
              onNext={nextLocation}
              onPrevious={previousLocation}
              onSkip={skipLocation}
              isPaused={isPaused}
              onToggleStats={() => setShowStats(true)}
              onToggleUI={() => setUIHidden(true)}
              currentLocation={currentLocation}
              totalLocations={tourData?.totalLocations}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Minimal UI when hidden */}
      <AnimatePresence>
        {isVisible && uiHidden && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="pointer-events-auto fixed bottom-4 right-4"
          >
            <button
              onClick={() => setUIHidden(false)}
              className="glass px-4 py-2 rounded-lg text-sm font-medium text-white hover:bg-white/10 transition-colors"
            >
              Show UI (H)
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default App
