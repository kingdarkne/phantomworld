import React from 'react'
import { motion } from 'framer-motion'
import { X, Trophy, Clock, MapPin, TrendingUp, Star, Users } from 'lucide-react'

export function TourStats({ onClose }) {
  // Mock stats data - in real implementation this would come from server
  const stats = {
    totalTours: 1247,
    totalPlayers: 342,
    averageDuration: 8.5, // minutes
    popularLocations: [
      { id: 'police_dept', name: 'Los Santos Police Department', visits: 892 },
      { id: 'hospital', name: 'Pillbox Hill Medical Center', visits: 756 },
      { id: 'bank', name: 'Fleeca Bank', visits: 623 },
      { id: 'city_hall', name: 'Los Santos City Hall', visits: 512 },
      { id: 'ammunation', name: 'Ammunation', visits: 445 }
    ],
    leaderboard: [
      { name: 'PhantomPlayer', toursCompleted: 15, totalTime: 127 },
      { name: 'CityExplorer', toursCompleted: 12, totalTime: 98 },
      { name: 'TourMaster', toursCompleted: 10, totalTime: 85 },
      { name: 'Newbie', toursCompleted: 8, totalTime: 67 },
      { name: 'CasualPlayer', toursCompleted: 6, totalTime: 45 }
    ]
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 flex items-center justify-center z-50 pointer-events-auto"
    >
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
      />

      {/* Modal */}
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        transition={{ type: "spring", stiffness: 200, damping: 20 }}
        className="relative w-full max-w-4xl mx-4"
      >
        <div className="glass rounded-2xl p-8 max-h-[80vh] overflow-y-auto">
          {/* Header */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
                <BarChart3 className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-3xl font-bold text-gradient">Tour Statistics</h2>
                <p className="text-white/70">Phantom World City Tour Analytics</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors"
            >
              <X className="w-6 h-6 text-white" />
            </button>
          </div>

          {/* Overview Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="card text-center"
            >
              <Trophy className="w-12 h-12 text-yellow-400 mx-auto mb-3" />
              <h3 className="text-3xl font-bold text-white mb-1">{stats.totalTours}</h3>
              <p className="text-white/70">Total Tours Completed</p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="card text-center"
            >
              <Users className="w-12 h-12 text-blue-400 mx-auto mb-3" />
              <h3 className="text-3xl font-bold text-white mb-1">{stats.totalPlayers}</h3>
              <p className="text-white/70">Unique Players</p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="card text-center"
            >
              <Clock className="w-12 h-12 text-green-400 mx-auto mb-3" />
              <h3 className="text-3xl font-bold text-white mb-1">{stats.averageDuration}m</h3>
              <p className="text-white/70">Average Tour Duration</p>
            </motion.div>
          </div>

          {/* Popular Locations */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="mb-8"
          >
            <h3 className="text-2xl font-bold text-white mb-4 flex items-center">
              <MapPin className="w-6 h-6 mr-2 text-purple-400" />
              Popular Locations
            </h3>
            <div className="space-y-3">
              {stats.popularLocations.map((location, index) => (
                <motion.div
                  key={location.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.5 + index * 0.1 }}
                  className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-gradient-to-r from-purple-500 to-blue-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                      {index + 1}
                    </div>
                    <div>
                      <h4 className="text-white font-medium">{location.name}</h4>
                      <p className="text-white/60 text-sm">{location.visits} visits</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <div className="w-32 h-2 bg-white/20 rounded-full overflow-hidden">
                      <motion.div
                        className="h-full bg-gradient-to-r from-purple-500 to-blue-500"
                        initial={{ width: 0 }}
                        animate={{ width: `${(location.visits / stats.popularLocations[0].visits) * 100}%` }}
                        transition={{ duration: 0.5, delay: 0.6 + index * 0.1 }}
                      />
                    </div>
                    <Star className="w-4 h-4 text-yellow-400" />
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Leaderboard */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
          >
            <h3 className="text-2xl font-bold text-white mb-4 flex items-center">
              <TrendingUp className="w-6 h-6 mr-2 text-green-400" />
              Tour Champions
            </h3>
            <div className="space-y-3">
              {stats.leaderboard.map((player, index) => (
                <motion.div
                  key={player.name}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: 0.6 + index * 0.1 }}
                  className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10"
                >
                  <div className="flex items-center space-x-3">
                    <div className="w-8 h-8 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-full flex items-center justify-center text-white font-bold text-sm">
                      {index + 1}
                    </div>
                    <div>
                      <h4 className="text-white font-medium">{player.name}</h4>
                      <p className="text-white/60 text-sm">{player.toursCompleted} tours • {player.totalTime} minutes</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Trophy className="w-4 h-4 text-yellow-400" />
                    <span className="text-white/80 text-sm">{player.toursCompleted} tours</span>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </motion.div>
    </motion.div>
  )
}
