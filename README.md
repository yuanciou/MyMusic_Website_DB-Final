# MyMusic Website
## Abstract
This website integrates Kaggle datasets and interacts with the Spotify API. Using database design and AWS Lambda functions, the database is hosted on AWS. The platform allows users to view weekly song rankings, create personalized playlists, and play a song-guessing game.
## Links
[:link: Link to MyMusic Website](https://briangodd.github.io/DB-Final/)
[:link: Link to Demo Video](https://drive.google.com/file/d/11ffIavDr8z9WQZw4mn8mbbTvNRoCXTPH/view?usp=sharing)
## Features:  
- **Home Page**  
- **Weekly Rankings**: Displays Spotify's daily top 50 songs.  
- **Song Search**: Users can search for songs by providing a song title, artist, or album name. The system first searches the database for the song. If the song is not found, it will be automatically added to the database.  
- **Playlist Creation**  
- **Song Guessing Game**: Users can set custom guessing criteria, such as artist, album, or song title (adding fun by guessing different versions). The program randomly plays a snippet of a song and provides multiple-choice options. Regardless of whether the user guesses correctly, they can choose to continue or end the game.  
## Database Schema
![Schema](https://github.com/yuanciou/MyMusic_Website_DB-Final/blob/main/schemaimg/img1.png)
