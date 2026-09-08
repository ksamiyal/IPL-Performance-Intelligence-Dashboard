-- IPL Performance Intelligence Dashboard
-- PostgreSQL | IPL 2008-2024 | 260,920 deliveries | 1,095 matches

-- Season-wise matches
SELECT season, COUNT(*) AS total_matches
FROM matches
GROUP BY season
ORDER BY season;

-- Team wins
SELECT winner, COUNT(*) AS wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY wins DESC;

-- Toss decision impact
SELECT
    toss_decision,
    COUNT(*) AS total_matches,
    COUNT(*) FILTER (WHERE toss_winner = winner) AS toss_winner_won,
    ROUND(100.0 * COUNT(*) FILTER (WHERE toss_winner = winner) / COUNT(*), 2) AS win_percentage
FROM matches
WHERE toss_winner IS NOT NULL AND winner IS NOT NULL
GROUP BY toss_decision
ORDER BY win_percentage DESC;

-- Player of the Match awards
SELECT player_of_match, COUNT(*) AS awards
FROM matches
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY awards DESC
LIMIT 15;

-- Team win percentage
WITH team_matches AS (
    SELECT team1 AS team FROM matches
    UNION ALL
    SELECT team2 AS team FROM matches
),
team_wins AS (
    SELECT winner AS team
    FROM matches
    WHERE winner IS NOT NULL
)
SELECT
    tm.team,
    COUNT(*) AS matches_played,
    COUNT(tw.team) AS wins,
    ROUND(100.0 * COUNT(tw.team) / COUNT(*), 2) AS win_percentage
FROM team_matches tm
LEFT JOIN team_wins tw ON tm.team = tw.team
GROUP BY tm.team
ORDER BY win_percentage DESC;

-- Venue-wise matches
SELECT venue, COUNT(*) AS matches_hosted
FROM matches
WHERE venue IS NOT NULL
GROUP BY venue
ORDER BY matches_hosted DESC
LIMIT 15;

-- Team wins by season
SELECT season, winner AS team, COUNT(*) AS wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, wins DESC;

-- Match result distribution
SELECT
    result,
    COUNT(*) AS matches,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM matches
WHERE result IS NOT NULL
GROUP BY result
ORDER BY matches DESC;

-- Powerplay / middle / death-over analysis
SELECT
    CASE
        WHEN over BETWEEN 1 AND 6 THEN 'Powerplay'
        WHEN over BETWEEN 17 AND 20 THEN 'Death Overs'
        ELSE 'Middle Overs'
    END AS phase,
    COUNT(*) AS balls,
    SUM(total_runs) AS runs_conceded,
    COUNT(*) FILTER (WHERE is_wicket = 1) AS wickets,
    ROUND(6.0 * SUM(total_runs) / NULLIF(COUNT(*), 0), 2) AS economy_rate
FROM deliveries
WHERE over BETWEEN 1 AND 20
GROUP BY 1
ORDER BY 1;

-- Batting performance view
CREATE OR REPLACE VIEW batting_performance AS
SELECT
    batter,
    SUM(batsman_runs) AS total_runs,
    COUNT(*) AS balls_faced,
    SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours,
    SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes,
    ROUND(100.0 * SUM(batsman_runs) / NULLIF(COUNT(*), 0), 2) AS strike_rate
FROM deliveries
GROUP BY batter;

-- Bowling performance view
CREATE OR REPLACE VIEW bowling_performance AS
SELECT
    bowler,
    COUNT(*) AS balls_bowled,
    SUM(total_runs) AS runs_conceded,
    COUNT(*) FILTER (WHERE is_wicket = 1) AS wickets,
    ROUND(6.0 * SUM(total_runs) / NULLIF(COUNT(*), 0), 2) AS economy_rate
FROM deliveries
GROUP BY bowler;

-- Team performance view
CREATE OR REPLACE VIEW team_performance AS
SELECT
    winner AS team,
    COUNT(*) AS total_wins,
    COUNT(DISTINCT season) AS seasons_won
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner;

-- Final team performance output
SELECT *
FROM team_performance
ORDER BY total_wins DESC;
