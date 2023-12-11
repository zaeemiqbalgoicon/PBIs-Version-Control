let
    GitHubRawUrl = "https://raw.githubusercontent.com/zaeemiqbalgoicon/PBIs-Version-Control/main/query1updated.sql",
    GetWebContents = () => Web.Contents(GitHubRawUrl),
    SqlQuery = Text.FromBinary(GetWebContents()),
    Source = Odbc.Query("dsn=mariadb", SqlQuery)
in
    Source
