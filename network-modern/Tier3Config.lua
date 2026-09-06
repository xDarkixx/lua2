-- BULDACITY TIER-3 CONFIG
return {
  nodeId="TIER3-CORE",
  port=31337,
  routeTimeout=20,
  heartbeatInterval=3,
  announceInterval=5,
  maxSeen=2048,
  maxPacketBytes=4096,
  dataDir="/home/buldacity-tier3",
  stateFile="/home/buldacity-tier3/state.dat",
  logFile="/home/buldacity-tier3/tier3.log",
  dashboard=true,
  dashboardRefresh=2,
  dashboardTitle="BULDACITY TIER-3 CONTROL",
  allowRemoteCommands=true,
  emergencyStopRequiresConfirm=true
}
