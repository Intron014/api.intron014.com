function updateCurrentSong() {
    const songInfo = document.querySelector('.song-info');
    const songIndicator = document.querySelector('.song-indicator');

    fetch('https://napi.intron014.com/intr0n/latest-song')
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            if (data.track && data.track.name && data.track.artist && data.track.artist['#text']) {
                const track = data.track;
                songInfo.innerHTML = `<a href="${track.url}">${track.name} by ${track.artist['#text']}</a>`;
                if(data.track['@attr'] && data.track['@attr'].nowplaying === 'true') {
                    songIndicator.classList.add('playing');
                }
            } else {
                throw new Error('Invalid track data');
            }
        })
        .catch(error => {
            console.error('Error fetching song data:', error.message);
            songInfo.textContent = 'Unable to fetch song data';
            songIndicator.classList.remove('playing');
        });
}

updateCurrentSong();
setInterval(updateCurrentSong, 30000);