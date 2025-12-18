# W.A.C.H. Feature Roadmap

**Stand:** 2025-12-17
**Fokus:** Calisthenics, Progressive Overload, Social Fitness

---

## Aktueller Status: MVP ✅

### Implementiert
- [x] Übungen CRUD
- [x] Session-Tracking mit Timer (Stopwatch/Countdown)
- [x] Progressive Overload Vorschläge
- [x] Lock/Unlock Modus
- [x] Tap-Zonen für Rep-Tracking
- [x] Dark Mode Design System
- [x] Offline-First (sembast/IndexedDB)
- [x] GitHub Pages Deployment

---

## Phase 3: Training Plans (Q1 2026)

### 3.1 Custom Training Plans
**Priorität:** Hoch

| Feature | Beschreibung |
|---------|--------------|
| Plan Builder | Drag & Drop Editor für eigene Trainingspläne |
| Übungs-Slots | Übungen zu Tagen/Wochen zuweisen |
| Rest Days | Pausentage definieren |
| Cycle-Length | 1-12 Wochen Zyklen |
| Plan Templates | Vorgefertigte Templates (PPL, Upper/Lower, Full Body) |

**Calisthenics-spezifisch:**
- Skill Progressions (z.B. Push-up → Diamond → Archer → One-Arm)
- Deload-Wochen automatisch einplanen
- Mobility/Stretching als eigene Kategorie

### 3.2 Plan Sharing
**Priorität:** Mittel

| Feature | Beschreibung |
|---------|--------------|
| Export as Link | Shareable URL zum Plan |
| QR Code Export | Plan als QR Code teilen |
| Plan Import | Fremde Pläne importieren |
| Plan Library | Community-Pläne durchstöbern |
| Creator Credits | Original-Ersteller wird angezeigt |

**Inspiration:** [Calistree](https://calisthenics.com/best-calisthenics-apps/) mit 1300+ Übungen

---

## Phase 4: Social Features (Q2 2026)

### 4.1 Gym Buddy Mode
**Priorität:** Hoch

| Feature | Beschreibung |
|---------|--------------|
| Session Share | Aktive Session per QR/Link teilen |
| Live Sync | Buddy sieht deine Reps in Echtzeit |
| Buddy Invite | Per QR Code oder Username |
| Shared Timer | Gemeinsamer Countdown |
| Chat | Einfache Nachrichten während Session |

**Use Case:** Du trainierst mit deinem Gym-Bro, beide tracken die gleiche Session, sehen gegenseitig den Fortschritt.

### 4.2 Session Sharing (Post-Workout)
**Priorität:** Mittel

| Feature | Beschreibung |
|---------|--------------|
| Session Summary Card | Schicke Grafik zum Teilen |
| Social Export | Instagram Story, WhatsApp, etc. |
| Stats Highlight | PRs, Streaks, Verbesserungen hervorheben |
| Privacy Levels | Public / Friends / Private |

**Inspiration:** [Strava](https://www.issaonline.com/blog/post/activity-tracker-competitions-with-friends-the-how-why) Segment-Sharing

---

## Phase 5: Battle Mode (Q2-Q3 2026)

### 5.1 1v1 Challenges
**Priorität:** Hoch

| Feature | Beschreibung |
|---------|--------------|
| Challenge erstellen | Übung + Ziel (z.B. "50 Push-ups") wählen |
| Invite via QR/Link | Gegner einladen |
| Async Battle | Nicht gleichzeitig nötig |
| Timer per Person | Jeder hat eigenen Timer |
| Leaderboard | Wer war schneller/mehr Reps? |

### 5.2 Group Battles (2-5 Personen)
**Priorität:** Mittel

| Feature | Beschreibung |
|---------|--------------|
| Room erstellen | Host erstellt Battle-Room |
| Join via Code | 4-6 stelliger Code zum Beitreten |
| Live Scoreboard | Echtzeit-Rangliste |
| Countdown Sync | Gemeinsamer Start-Countdown |
| Winner Animation | Konfetti für Gewinner |

### 5.3 Challenge Types
| Typ | Beschreibung |
|-----|--------------|
| **Speed Run** | Wer schafft X Reps am schnellsten? |
| **Max Reps** | Wer schafft die meisten Reps in Y Minuten? |
| **Endurance** | Wer hält am längsten durch? (z.B. Plank) |
| **AMRAP** | As Many Rounds As Possible in Z Minuten |

**Inspiration:** [BattleFit](https://battlefit.web.app/) - Challenge friends at any workout

---

## Phase 6: Gamification (Q3 2026)

### 6.1 Skill Tree System
**Priorität:** Mittel

| Feature | Beschreibung |
|---------|--------------|
| Visual Skill Tree | Übungen als verbundene Nodes |
| Unlock System | Fortgeschrittene Übungen freischalten |
| Prerequisites | z.B. "10 Dips" für "Ring Dips" |
| Progress Indicator | Prozent-Fortschritt pro Skill |

**Calisthenics Skills:**
```
Push-ups → Diamond → Archer → One-Arm
Pull-ups → Wide Grip → L-Sit Pull-up → Muscle-up
Squats → Pistol Progression → Shrimp Squat
Plank → Side Plank → Dragon Flag
```

**Inspiration:** [Calistree](https://dieringe.com/blog/calisthenics-apps) Skill Tree System

### 6.2 Achievements & Badges
| Badge | Bedingung |
|-------|-----------|
| First Blood | Erste Session abgeschlossen |
| Streak Master | 7 Tage am Stück trainiert |
| Century Club | 100 Reps in einer Session |
| Early Bird | Training vor 7 Uhr |
| Night Owl | Training nach 22 Uhr |
| PR Breaker | Personal Record gebrochen |
| Consistency King | 30 Tage Streak |

### 6.3 Streaks & Motivation
| Feature | Beschreibung |
|---------|--------------|
| Daily Streak | Tage am Stück trainiert |
| Weekly Goal | X Sessions pro Woche |
| Monthly Challenge | Community Challenge jeden Monat |
| Streak Recovery | 1x pro Monat Streak retten |

---

## Phase 7: Analytics & Insights (Q4 2026)

### 7.1 Progress Visualization
| Feature | Beschreibung |
|---------|--------------|
| Volume Charts | Gesamtvolumen über Zeit |
| PR History | Alle Personal Records |
| Muscle Heatmap | Welche Muskeln trainiert? |
| Trend Analysis | Verbesserung/Verschlechterung |

### 7.2 Smart Recommendations
| Feature | Beschreibung |
|---------|--------------|
| Rest Suggestion | "Du solltest heute pausieren" |
| Weak Points | Untertrainierte Bereiche |
| Plateau Detection | Stagnation erkennen |
| Deload Reminder | Deload-Woche vorschlagen |

**Inspiration:** [Dr. Muscle](https://dr-muscle.com/progressive-overload-app-gain-muscle-strength/) AI-basierte Empfehlungen

---

## Phase 8: Lifestyle Integration (2027)

### 8.1 Habit Tracking
| Feature | Beschreibung |
|---------|--------------|
| Water Intake | Trinken tracken |
| Sleep Quality | Schlaf loggen |
| Nutrition Log | Einfache Mahlzeiten-Notiz |
| Daily Check-in | Wie fühlst du dich? |

### 8.2 Wearable Integration
| Integration | Beschreibung |
|-------------|--------------|
| Apple Health | Steps, Heart Rate sync |
| Google Fit | Android Integration |
| Garmin | Watch-Support |
| Samsung Health | Galaxy Watch Support |

### 8.3 Widget & Notifications
| Feature | Beschreibung |
|---------|--------------|
| Home Widget | Streak, nächstes Training |
| Smart Reminders | Basierend auf Gewohnheiten |
| PR Celebration | Push bei neuem Record |

---

## Technische Voraussetzungen

### Für Social Features (Phase 4-5)
- [ ] User Authentication (Anonymous + Optional Account)
- [ ] Real-time Database (Firebase/Supabase)
- [ ] QR Code Generation/Scanning
- [ ] Deep Links für App-Sharing
- [ ] Push Notifications

### Für Battle Mode (Phase 5)
- [ ] WebSocket/Real-time Sync
- [ ] Room Management
- [ ] Matchmaking Logic
- [ ] Anti-Cheat (Basic)

### Für Analytics (Phase 7)
- [ ] Charts Library (fl_chart)
- [ ] Data Export (CSV/JSON)
- [ ] Cloud Backup

---

## Priorisierung nach User Value

| Rang | Feature | Impact | Aufwand |
|------|---------|--------|---------|
| 1 | Custom Training Plans | Sehr hoch | Mittel |
| 2 | 1v1 Battle Mode | Hoch | Hoch |
| 3 | Session Sharing | Hoch | Niedrig |
| 4 | Gym Buddy Mode | Hoch | Hoch |
| 5 | Achievements | Mittel | Niedrig |
| 6 | Skill Tree | Mittel | Mittel |
| 7 | Analytics | Mittel | Mittel |
| 8 | Wearables | Niedrig | Hoch |

---

## Konkurrenz-Analyse

| App | Stärke | W.A.C.H. Vorteil |
|-----|--------|------------------|
| [Calistree](https://calisthenics.com/best-calisthenics-apps/) | 1300+ Übungen, Skill Tree | Einfachheit, Countdown-USP |
| [THENX](https://thehybridathlete.com/best-calisthenics-app/) | Video-Qualität | Offline-First, Battle Mode |
| [Calisteniapp](https://calisthenics.com/calisteniapp-review/) | 500+ Free Workouts | Social Features |
| [Strong](https://apps.apple.com/ph/app/strong-workout-tracker-gym-log/id464254577) | PR Tracking | Calisthenics-Fokus |
| [BattleFit](https://battlefit.web.app/) | Battle Feature | All-in-One Lösung |
| [Hevy](https://www.hevyapp.com/progressive-overload/) | Community | Progressive Overload Focus |

---

## USPs von W.A.C.H.

1. **Countdown-Timer** - Zeit der letzten Session unterbieten
2. **Lock-Modus** - Keine Fehlklicks beim Training
3. **Battle Mode** - Echtzeit-Wettkämpfe mit Freunden
4. **Calisthenics-First** - Optimiert für Bodyweight
5. **Offline-First** - Funktioniert ohne Internet
6. **Open Source** - Community-driven

---

*Zuletzt aktualisiert: 2025-12-17*
