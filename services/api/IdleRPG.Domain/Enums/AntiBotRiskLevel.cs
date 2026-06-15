namespace IdleRPG.Domain.Enums;

public enum AntiBotRiskLevel
{
    Normal = 0,           // 0-20: sin accion
    SilentMonitor = 1,    // 21-40: logging adicional
    VisibleWarning = 2,   // 41-60: banner en UI
    GameplayRestrict = 3, // 61-70: drop rate al 50%
    MarketRestrict = 4,   // 71-80: no listar en Steam Market
    TempSuspension = 5,   // 81-90: ban temporal 24-72h
    PermanentBan = 6      // 91-100: ban permanente
}
