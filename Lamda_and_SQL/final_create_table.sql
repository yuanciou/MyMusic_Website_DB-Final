import axios from 'axios';
import pkg from 'pg';
const { Pool, Client } = pkg;
const pool = new Pool({
  user: 'postgres',
  host: 'database-2.c8dhylstxkf5.us-east-1.rds.amazonaws.com',
  database: 'postgres',
  password: '1qaz2wsx',
  port: 5432,
  ssl: {
    rejectUnauthorized: false
  }
});
var cache_genre = [];
var cache_artist = [];
var cache_song_to_artist = [];
// var cache_market = [];
var cache_artist_of_album = [];
var cache_song = [];
var cache_constraints = [];
var cache_album = [];
var cache_song_to_album = [];
var cache_parameter = [];

const GetToken = async() => {
  const client_id = '7672a8e6e03a4ab7af57cb5dfa8f23eb';
  const client_secret = '9b93872417764086b08642d821a85643';
  const token_url = 'https://accounts.spotify.com/api/token';
  const data = 'grant_type=client_credentials';
  const response = await axios.post(token_url, data, {
    headers: {
      'Authorization': 'Basic ' + (new Buffer.from(client_id + ':' + client_secret).toString('base64')),
      'Content-Type': 'application/x-www-form-urlencoded' 
    }
  });
  return response.data.access_token;
};

const GetAlbumsFromArtist = async(token, artist_id) => {
  var album_id_list = [];
  const url = `https://api.spotify.com/v1/artists/${artist_id}/albums?include_groups=single%2Calbum`;
  
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    response.data.items.forEach((album) => {
      // console.log(album.id);
      album_id_list.push(album.id);
    });
  }
  catch(error){
    console.log(error);
  }
  // console.log(album_id_list[0]);
  return album_id_list;
};

const GetTracksFromAlbum = async(token, album_id) => {
  let track_id_list = [];
  const url = `https://api.spotify.com/v1/albums/${album_id}/tracks?limit=50`;
  
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    response.data.items.forEach((track) => {
      track_id_list.push(track.id);
    });
  }
  catch(error){
    console.log(error);
  }
  // console.log(track_id_list[0]);
  return track_id_list;
};

const GetTracksFromAlbums = async(token, album_id_list) => {
  let track_id_list = [];
  // console.log(album_id_list);
  for(let i=0;i<album_id_list.length;i++){
    // console.log(album_id_list[i]);
    // console.log(await GetTracksFromAlbum(token, album_id_list[i]));
    track_id_list = track_id_list.concat(await GetTracksFromAlbum(token, album_id_list[i]));//change to async
  }
  return track_id_list;
};

const GetTracksData_Limit = async(token, track_id_list_limit) => {
  let track_data = [];
  var url = 'https://api.spotify.com/v1/tracks?ids='+track_id_list_limit[0];
  for(var i=1;i<track_id_list_limit.length;i++){
    url+='%2C'+track_id_list_limit[i];
  }
  try{
    // console.log(url);
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    response.data.tracks.forEach((track) => {
      var temp = [];
      var t_genre = [];
      var t_artist = [];
      var t_song_to_artist = [];
      // var t_market = [];
      var t_artist_of_album = [];
      var t_song = [];
      var t_constraints = [];
      var t_album = [];
      var t_song_to_album = [];
      var t_parameter = [];
      // console.log(track.artists[0]);
      t_genre.push(track.artists[0].id, track.artists[0]?.genres||'null');
      t_artist.push(track.artists[0].id, track.artists[0].name, track.artists[0]?.followers||null);
      t_song_to_artist.push(track.id, track.artists[0].id);
      t_artist_of_album.push(track.artists[0].id, track.album.id);
      t_song.push(track.id, track.name, track.popularity);
      //console.log(typeof track.album.release_date);
      var t_date = (track.album.release_date.length==10) ? track.album.release_date:null;
      t_constraints.push(track.id, track.duration_ms, t_date);
      t_album.push(track.album.id, track.album.name, track.album.album_type, track.album.total_tracks);
      t_song_to_album.push(track.id, track.album.id, track.track_number);
      t_parameter.push(track.id);
      // console.log(t_album);
      cache_genre.push(t_genre);
      cache_artist.push(t_artist);
      cache_song_to_artist.push(t_song_to_artist);
      cache_artist_of_album.push(t_artist_of_album);
      cache_song.push(t_song);
      cache_constraints.push(t_constraints);
      cache_album.push(t_album);
      cache_song_to_album.push(t_song_to_album);
      cache_parameter.push(t_parameter);
      temp.push(track.album.album_type, track.album.total_tracks, track.album.id, track.album.name, 
                track.artists[0].genres, track.artists[0].id, track.artists[0].name, track.artists[0].followers,
                track.avaliable_markets, track.duration_ms, track.id, track.name, track.popularity, track.track_number,
                track.album.release_date);
      track_data.push(temp);
      // console.log(track_data);
    });
  }
  catch(error){
    console.log(error);
  }
  return track_data;

};

const GetTracksData = async(token, track_id_list) => {
  var track_data = [];
  var _track_id_list = [...track_id_list];
  var track_feature_data = await GetTracksAudioFeatures(token, _track_id_list);
  
  while(track_id_list.length > 0){
    var temp = track_id_list.slice(0, Math.min(49, track_id_list.length));
    track_data = track_data.concat(await GetTracksData_Limit(token, temp));
    track_id_list.splice(0, Math.min(49, track_id_list.length));
  }
  
  // console.log(track_feature_data);
  for(let i=0;i<track_feature_data.length;i++){
    cache_parameter[i] = cache_parameter[i].concat(track_feature_data[i]);
  }
  return track_data;
};

const GetTracksAudioFeatures_limit = async(token, track_id_list_limit) => {
  let track_feature_data = [];
  var url = 'https://api.spotify.com/v1/audio-features?ids='+track_id_list_limit[0];
  for(var i=1;i<track_id_list_limit.length;i++){
    url+='%2C'+track_id_list_limit[i];
  }
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    response.data.audio_features.forEach((track) => {
      var temp = [];
      temp.push(track?.acousticness||null, track?.danceability||null, track?.energy||null, 
                track?.instrumentalness||null, track?.key||null, track?.liveness||null, track?.loudness||null,
                track?.mode||null, track?.speechiness||null, track?.tempo||null, 
                track?.time_signature||null, track?.valence||null);
      track_feature_data.push(temp);
    });
  }
  catch(error){
    console.log(error);
  }
  return track_feature_data;
};

const GetTracksAudioFeatures = async(token, track_id_list) => {
  var track_feature_data = [];
  while(track_id_list.length > 0){
    var temp = track_id_list.slice(0, Math.min(49, track_id_list.length));
    track_feature_data = track_feature_data.concat(await GetTracksAudioFeatures_limit(token, temp));
    track_id_list.splice(0, Math.min(49, track_id_list.length));
  }
  return track_feature_data;
};

const GetArtistFromTrack = async(token, track_id) => {
  var artist_id = '';
  var url = 'https://api.spotify.com/v1/tracks/'+track_id;
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    artist_id = response.data.artists[0].id;
  }
  catch(error){
    console.log(error);
  }
  return artist_id;
};

const GetArtistFromAlbum = async(token, album_id) => {
  var artist_id = '';
  var url = 'https://api.spotify.com/v1/albums/'+album_id;
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    artist_id = response.data.artists[0].id;
  }
  catch(error){
    console.log(error);
  }
  return artist_id;
};

const WriteCache = async() => {
  for(let i=0;i<cache_album.length;i++){
    console.log(await pool.query(`insert into album values($1, $2, $3, $4) ON CONFLICT (album_id) DO NOTHING;`, 
                [cache_album[i][0],cache_album[i][1],cache_album[i][2],cache_album[i][3]]));
  }
  for(let i=0;i<cache_song.length;i++){
    console.log(await pool.query(`insert into song values($1, $2, $3) ON CONFLICT (track_id) DO UPDATE SET popularity = EXCLUDED.popularity;`, 
                [cache_song[i][0],cache_song[i][1],cache_song[i][2]]));
  }
  for(let i=0;i<cache_artist.length;i++){
    console.log(await pool.query(`insert into artist(artist_id, artist_name, artist_followers) values($1, $2, $3) ON CONFLICT (artist_id) DO UPDATE SET artist_followers = EXCLUDED.artist_followers;`, 
                [cache_artist[i][0],cache_artist[i][1], cache_artist[i][2]]));
  }
  for(let i=0;i<cache_artist_of_album.length;i++){
    console.log(await pool.query(`insert into artist_of_album values($1, $2) ON CONFLICT (artist_id, album_id) DO NOTHING;`, 
                [cache_artist_of_album[i][0],cache_artist_of_album[i][1]]));
  }
  for(let i=0;i<cache_song_to_album.length;i++){
    console.log(await pool.query(`insert into song_to_album values($1, $2, $3) ON CONFLICT (track_id) DO NOTHING;`, 
                [cache_song_to_album[i][0],cache_song_to_album[i][1],cache_song_to_album[i][2]]));
  }
  for(let i=0;i<cache_genre.length;i++){
    console.log(await pool.query(`insert into genre values($1, $2) ON CONFLICT (artist_id, artist_genre) DO NOTHING;`,
                [cache_genre[i][0],cache_genre[i][1]]));
  }
  for(let i=0;i<cache_song_to_artist.length;i++){
    console.log(await pool.query(`insert into song_to_artist values($1, $2) ON CONFLICT (track_id, artist_id) DO NOTHING;`, 
                [cache_song_to_artist[i][0],cache_song_to_artist[i][1]]));
  }
  for(let i=0;i<cache_constraints.length;i++){
    /*console.log(*/await pool.query(`insert into constraints values($1, $2, $3) ON CONFLICT (track_id) DO NOTHING;`, 
                [cache_constraints[i][0],cache_constraints[i][1],cache_constraints[i][2]])/*)*/;
  }
  for(let i=0;i<cache_parameter.length;i++){
    console.log(await pool.query(`insert into parameter values($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13) ON CONFLICT (track_id) DO NOTHING;`,
                [cache_parameter[i][0],cache_parameter[i][1],cache_parameter[i][2],cache_parameter[i][3],cache_parameter[i][4],
                cache_parameter[i][5],cache_parameter[i][6],cache_parameter[i][7],cache_parameter[i][8],cache_parameter[i][9],
                cache_parameter[i][10],cache_parameter[i][11],cache_parameter[i][12]]));
  }
}

const GetTopPlaylist = async(token, play_list_id) => {
  var track_ids = [];
  var url = 'https://api.spotify.com/v1/playlists/'+play_list_id;
  try{
    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    response.data.tracks.items.forEach((item) => {
      console.log(item.track.name);
    });
  }
  catch(error){
    console.log(error);
  }
  return track_ids;
};

export const handler = async (event) => {
  pool.connect();
  const metaData = {
    headers: {
      "Access-Control-Allow-Origin": "*",
    },
  };


  var token = await GetToken();
  // var artist_id = '2elBjNSdBE2Y3f0j1mjrql';
  const operation = event.operation;
  let id_from_post = [];
  let d = new Date();
  let current_date = d.getFullYear()+'/'+d.getMonth()+1+'/'+ d.getDate();
  id_from_post.push(event.id);
  switch(operation){
    case 'UpdateByTrack':
          await GetTracksData(token, id_from_post);
          await WriteCache();
          break;
    case 'UpdateByAlbum':
          var track_list_ByAlbum = await GetTracksFromAlbums(token, id_from_post);
          await GetTracksData(token, track_list_ByAlbum);
          await WriteCache();
          break;
    case 'UpdateByArtist':
          var album_list_ByArtist = await GetAlbumsFromArtist(token, id_from_post);
          var track_list_ByArtist = await GetTracksFromAlbums(token, album_list_ByArtist);
          await GetTracksData(token, track_list_ByArtist);
          await WriteCache();
          break;
    case 'AddUser':
          console.log(await pool.query('insert into user_information values($1, $2, $3)',[event.user_name, event.user_password, event.user_nickname]));
          break;
    case 'UpdateSongList':
          let ret = await pool.query('select count(*) from song where track_id=$1',[event.track_id])
          if(ret.rows[0].count!=0){
            console.log(await pool.query('insert into song_list values($1, $2, $3)',[event.user_name, event.track_id, current_date]));
          }
          else{
            await GetTracksData(token, event.track_id);
            await WriteCache();
            console.log(await pool.query('insert into song_list values($1, $2, $3)',[event.user_name, event.track_id, current_date]));
          }
          break;
    case 'UpdateGuessRanking':
          await pool.query('insert into guess_ranking_list values($1, $2, $3) ON CONFLICT (user_name) DO UPDATE SET right_number = guess_ranking_list.right_number + EXCLUDED.right_number;',[event.user_name, event.user_nickname, event.increase_by]);
          break;
    case 'GetToken':
          console.log(token);
          return {
            ...metaData,
            statusCode: 200,
            body: token
          };
          break;
    default:
          return ('Unknown operation: ${operation}');
  }

  // console.log(track_data);

  // console.log(cache_song_to_artist);
  // console.log(await pool.query(`insert into test values('a', '測試')`));
  // console.log(cache_album[0][0]);
  // console.log(await pool.query(`DELETE FROM test WHERE track_id='a';`));
  // console.log(await pool.query(`ALTER TABLE test ADD PRIMARY KEY (track_id);`));
  // for(var i=0;i<cache_album.length;i++){
  //   console.log(await pool.query(`insert into test values('${cache_album[i][0]}','${cache_album[i][1]}') ON CONFLICT (track_id) DO NOTHING;`));    
  // }
  // console.log(await pool.query(`select * from test`));
  // console.log(await pool.query(`select * from album where album_name='阿姆斯壯'`));
  
  // console.log(cache_album);
  
  
  // console.log(await pool.query(`select * from genre join artist on genre.artist_id=artist.artist_id join artist_of_album on artist_of_album.artist_id=artist.artist_id join album on album.album_id=artist_of_album.album_id where artist_name='NewJeans'`));
  // console.log(cache_parameter);
  // console.log(await pool.query(`select * from song join parameter on song.track_id=parameter.track_id limit 1`));
  // console.log(await pool.query(`select * from song join constraints on song.track_id=constraints.track_id limit 1`));
  // console.log(await pool.query(`select * from song join song_to_artist on song.track_id=song_to_artist.track_id where artist_id='4aayM0ChfIX46qI4eBCgMN'`));
  // console.log(await pool.query(`select * from genre join artist on genre.artist_id=artist.artist_id where artist_name='趙翊帆YI94'`));
  // console.log(await pool.query(`select * from song_to_album where album_id = '0kLA3BfzNon9DuWTNpvQt1'`));
  // console.log(await pool.query(`select * from artist_of_album join artist on artist_of_album.artist_id=artist.artist_id where artist_name='趙翊帆YI94'`));
  // console.log(await pool.query(`select * from album where album_id='0kLA3BfzNon9DuWTNpvQt1'`));
  // pool.end();

  return {
    ...metaData,
    statusCode: 200,
    body: JSON.stringify(operation),
  };
};