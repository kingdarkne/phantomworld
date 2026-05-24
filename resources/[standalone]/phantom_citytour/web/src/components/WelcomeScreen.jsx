import React from 'react'
import { motion } from 'framer-motion'
import { MapPin, Sparkles, Star } from 'lucide-react'

export function WelcomeScreen() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0, transition: { duration: 1 } }}
      className="fixed inset-0 flex items-center justify-center z-50 pointer-events-none"
    >
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.8, opacity: 0 }}
        transition={{ duration: 0.8, ease: "easeOut" }}
        className="text-center max-w-4xl mx-auto px-8"
      >
        {/* Animated Background Elements */}
        <div className="absolute inset-0 flex items-center justify-center">
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
            className="absolute"
          >
            <Sparkles className="w-64 h-64 text-purple-500/20" />
          </motion.div>
          <motion.div
            animate={{ rotate: -360 }}
            transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
            className="absolute"
          >
            <Star className="w-48 h-48 text-blue-500/20" />
          </motion.div>
        </div>

        {/* Main Content */}
        <motion.div
          initial={{ y: 50, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3, duration: 0.8 }}
          className="relative z-10"
        >
          {/* Icon */}
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.5, type: "spring", stiffness: 200 }}
            className="mb-8 flex justify-center"
          >
            <div className="relative">
              <motion.div
                animate={{ scale: [1, 1.1, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="absolute inset-0 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full blur-xl opacity-50"
              />
              <div className="relative bg-gradient-to-r from-purple-600 to-blue-600 p-6 rounded-full">
                <MapPin className="w-16 h-16 text-white" />
              </div>
            </div>
          </motion.div>

          {/* Title */}
          <motion.h1
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.7, duration: 0.8 }}
            className="text-6xl md:text-8xl font-bold text-gradient mb-6 leading-tight"
          >
            Phantom World
          </motion.h1>

          {/* Subtitle */}
          <motion.h2
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.9, duration: 0.8 }}
            className="text-2xl md:text-3xl font-semibold text-white/90 mb-8"
          >
            City Tour Experience
          </motion.h2>

          {/* Description */}
          <motion.p
            initial={{ y: 30, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 1.1, duration: 0.8 }}
            className="text-lg text-white/80 max-w-2xl mx-auto mb-12 leading-relaxed"
          >
            Discover the amazing locations, services, and hidden gems of Phantom World. 
            Your guided journey begins now...
          </motion.p>

          {/* Loading Animation */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1.3, duration: 0.8 }}
            className="flex justify-center items-center space-x-2"
          >
            <motion.div
              animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
              transition={{ duration: 1.5, repeat: Infinity }}
              className="w-3 h-3 bg-purple-500 rounded-full"
            />
            <motion.div
              animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
              transition={{ duration: 1.5, repeat: Infinity, delay: 0.2 }}
              className="w-3 h-3 bg-blue-500 rounded-full"
            />
            <motion.div
              animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
              transition={{ duration: 1.5, repeat: Infinity, delay: 0.4 }}
              className="w-3 h-3 bg-purple-500 rounded-full"
            />
          </motion.div>
        </motion.div>

        {/* Floating Particles */}
        {[...Array(20)].map((_, i) => (
          <motion.div
            key={i}
            initial={{ 
              x: Math.random() * window.innerWidth - window.innerWidth / 2,
              y: Math.random() * window.innerHeight - window.innerHeight / 2,
              opacity: 0
            }}
            animate={{ 
              x: Math.random() * window.innerWidth - window.innerWidth / 2,
              y: Math.random() * window.innerHeight - window.innerHeight / 2,
              opacity: [0, 1, 0]
            }}
            transition={{ 
              duration: 3 + Math.random() * 2,
              repeat: Infinity,
              delay: Math.random() * 2,
              ease: "easeInOut"
            }}
            className="absolute w-1 h-1 bg-white rounded-full"
          />
        ))}
      </motion.div>
    </motion.div>
  )
}
