window.onload = function () {
  // On suppose que l’API Google est chargée
  const inputField = document.getElementById("my-autocomplete");
  if (!inputField || !google || !google.maps) return;

  const autocomplete = new google.maps.places.Autocomplete(inputField, {
    types: ["geocode"], // ou 'address'
    componentRestrictions: { country: "fr" },
    fields: ["formatted_address", "geometry", "name", "place_id"],
  });

  autocomplete.addListener("place_changed", () => {
    const place = autocomplete.getPlace();
    if (!place || !place.geometry) {
      console.log("Aucune geometry trouvée ou place invalide.");
      return;
    }
    const lat = place.geometry.location.lat();
    const lng = place.geometry.location.lng();
    console.log("Adresse complète :", place.formatted_address);
    console.log("Coordonnées :", lat, lng);

    // Ici on peut communiquer à Flutter via interop (voir étape 4).
    if (window.flutter_injectAddress) {
      window.flutter_injectAddress(place.formatted_address, lat, lng);
    }
  });
};
