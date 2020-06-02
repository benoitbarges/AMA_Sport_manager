import mapboxgl from 'mapbox-gl';
import Amadeus from 'amadeus';

const fitMapToMarkers = (map, marker) => {
  const bounds = new mapboxgl.LngLatBounds();
  bounds.extend([ marker.lng, marker.lat ]);
  map.fitBounds(bounds, { padding: 70, maxZoom: 13, duration: 0 });
};


const initMapbox = () => {
  const mapElement = document.getElementById('map');
  const amadeus = new Amadeus({
    clientId: mapElement.dataset.amadeusId,
    clientSecret: mapElement.dataset.amadeusSecret
  });
  if (mapElement) {
    mapboxgl.accessToken = mapElement.dataset.mapboxApiKey;
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v10'
    });
    const marker = JSON.parse(mapElement.dataset.marker);
    amadeus.shopping.hotelOffers.get({
      latitude: marker.lat,
      longitude: marker.lng,
      radius: 3,
      radiusUnit: 'KM',
    }).then(response => response.data.forEach((result) => {
      const infoWindow = `  <div class='window-image'></div>
                            <div class='details ml-3'>
                              <div class='top mt-2'>
                              <h5>${result.hotel.name}</h5>
                              <p>${result.hotel.rating}/5</p>
                              </div>
                              <p>${result.hotel.hotelDistance.distance}km from the stadium</p>
                              <p class="mt-2"><strong>${result.offers[0].price.total} ${result.offers[0].price.currency}</strong> per night</p>
                            </div>`
      const element = document.createElement('div');
      element.className = 'marker';
      element.style.backgroundImage = `url('https://image.flaticon.com/icons/svg/2933/2933921.svg')`;
      element.style.backgroundSize = 'contain';
      element.style.width = '25px';
      element.style.height = '25px';
      const popup = new mapboxgl.Popup().setHTML(infoWindow);
      new mapboxgl.Marker(element)
      .setLngLat([ result.hotel.longitude, result.hotel.latitude ])
      .setPopup(popup)
      .addTo(map);
    }));
    new mapboxgl.Marker()
      .setLngLat([ marker.lng, marker.lat ])
      .addTo(map);
    fitMapToMarkers(map, marker);
  }
};


export { initMapbox };
