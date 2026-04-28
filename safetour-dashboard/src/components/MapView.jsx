import { useEffect } from 'react';
import L from 'leaflet';
import {
  LayerGroup,
  LayersControl,
  MapContainer,
  Marker,
  Popup,
  TileLayer,
  useMap,
} from 'react-leaflet';

import AlertBadge from './AlertBadge.jsx';

const MAPTILER_KEY = import.meta.env.VITE_MAPTILER_KEY || '';
const TILE_URL = `https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${MAPTILER_KEY}`;

const sosIcon = new L.DivIcon({
  className: '',
  html: '<div class="sos-pulse"></div>',
  iconSize: [22, 22],
  iconAnchor: [11, 11],
});

const policeIcon = new L.DivIcon({
  className: '',
  html: '<div class="marker-pin pin-police"></div>',
  iconSize: [20, 20],
  iconAnchor: [10, 20],
});

const hospitalIcon = new L.DivIcon({
  className: '',
  html: '<div class="marker-pin pin-hospital"></div>',
  iconSize: [20, 20],
  iconAnchor: [10, 20],
});

const embassyIcon = new L.DivIcon({
  className: '',
  html: '<div class="marker-pin pin-embassy"></div>',
  iconSize: [20, 20],
  iconAnchor: [10, 20],
});

const safeZoneIcon = new L.DivIcon({
  className: '',
  html: '<div class="marker-pin pin-safe"></div>',
  iconSize: [20, 20],
  iconAnchor: [10, 20],
});

const alertIcon = new L.DivIcon({
  className: '',
  html: '<div class="alert-triangle"></div>',
  iconSize: [20, 18],
  iconAnchor: [10, 18],
});

function zoneIcon(type) {
  switch (type) {
    case 'police': return policeIcon;
    case 'hospital': return hospitalIcon;
    case 'embassy': return embassyIcon;
    default: return safeZoneIcon;
  }
}

function pointFromGeoJson(item) {
  const coordinates = item.location?.coordinates;
  if (!Array.isArray(coordinates) || coordinates.length < 2) return null;
  return [coordinates[1], coordinates[0]];
}

function timeAgo(dateStr) {
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.floor(hrs / 24)}d ago`;
}

function FlyToSelectedSos({ sosReports, selectedSosId }) {
  const map = useMap();
  useEffect(() => {
    if (!selectedSosId) return;
    const report = sosReports.find((r) => r._id === selectedSosId);
    const pt = report ? pointFromGeoJson(report) : null;
    if (pt) map.flyTo(pt, 14, { duration: 1.2 });
  }, [selectedSosId, sosReports, map]);
  return null;
}

function SosMarkers({ sosReports, onRespond }) {
  return sosReports.map((report) => {
    const pt = pointFromGeoJson(report);
    if (!pt) return null;
    const [lat, lng] = pt;
    return (
      <Marker key={report._id} position={pt} icon={sosIcon}>
        <Popup>
          <div style={{ minWidth: 200 }}>
            <div style={{ marginBottom: 6 }}>
              <strong style={{ textTransform: 'capitalize' }}>{report.emergencyType}</strong>
              {' '}
              <span
                style={{
                  background: report.status === 'pending' ? '#ef4444' : '#f59e0b',
                  color: 'white',
                  borderRadius: 4,
                  padding: '1px 6px',
                  fontSize: 11,
                  fontWeight: 700,
                  textTransform: 'uppercase',
                }}
              >
                {report.status}
              </span>
            </div>
            <div style={{ color: '#374151', fontSize: 13 }}>
              {report.userId?.displayName || report.userId?.email || 'Tourist'}
            </div>
            {report.description && (
              <div style={{ color: '#6b7280', fontSize: 12, marginTop: 4 }}>
                {report.description}
              </div>
            )}
            <div style={{ color: '#9ca3af', fontSize: 11, marginTop: 4 }}>
              {lat.toFixed(5)}, {lng.toFixed(5)}
            </div>
            <button
              onClick={() => onRespond?.(report)}
              style={{
                marginTop: 8,
                background: '#ef4444',
                color: 'white',
                border: 'none',
                borderRadius: 6,
                padding: '4px 12px',
                fontSize: 12,
                fontWeight: 700,
                cursor: 'pointer',
                width: '100%',
              }}
            >
              Respond →
            </button>
          </div>
        </Popup>
      </Marker>
    );
  });
}

function ZoneMarkers({ safeZones }) {
  return safeZones.map((zone) => {
    const pt = pointFromGeoJson(zone);
    if (!pt) return null;
    return (
      <Marker key={zone._id} position={pt} icon={zoneIcon(zone.type)}>
        <Popup>
          <div style={{ minWidth: 160 }}>
            <strong>{zone.name}</strong>
            <div>
              <span
                style={{
                  background: '#e5e7eb',
                  borderRadius: 4,
                  padding: '1px 6px',
                  fontSize: 11,
                  fontWeight: 700,
                  textTransform: 'capitalize',
                }}
              >
                {zone.type?.replace('_', ' ')}
              </span>
            </div>
            {zone.address && (
              <div style={{ color: '#6b7280', fontSize: 12, marginTop: 4 }}>{zone.address}</div>
            )}
            {zone.phone && (
              <div style={{ color: '#374151', fontSize: 12, marginTop: 2 }}>{zone.phone}</div>
            )}
          </div>
        </Popup>
      </Marker>
    );
  });
}

function AlertMarkers({ alerts }) {
  return alerts.map((alert) => {
    const pt = pointFromGeoJson(alert);
    if (!pt) return null;
    return (
      <Marker key={alert._id} position={pt} icon={alertIcon}>
        <Popup>
          <div style={{ minWidth: 180 }}>
            <strong style={{ fontSize: 13 }}>{alert.title}</strong>
            <div style={{ marginTop: 4 }}>
              <AlertBadge severity={alert.severity} />
            </div>
            {alert.description && (
              <div style={{ color: '#6b7280', fontSize: 12, marginTop: 4 }}>{alert.description}</div>
            )}
            <div style={{ color: '#9ca3af', fontSize: 11, marginTop: 4 }}>
              {alert.source} · {timeAgo(alert.createdAt)}
            </div>
          </div>
        </Popup>
      </Marker>
    );
  });
}

export default function MapView({
  sosReports = [],
  safeZones = [],
  alerts = [],
  selectedSosId = null,
  onRespond,
}) {
  return (
    <MapContainer
      center={[7.8731, 80.7718]}
      zoom={8}
      className="h-full w-full"
      style={{ background: '#1e293b' }}
    >
      <LayersControl position="topright">
        <LayersControl.BaseLayer checked name="Streets">
          <TileLayer
            attribution='&copy; <a href="https://www.maptiler.com/">MapTiler</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url={TILE_URL}
            tileSize={512}
            zoomOffset={-1}
          />
        </LayersControl.BaseLayer>
        <LayersControl.Overlay checked name="SOS Reports">
          <LayerGroup>
            <SosMarkers sosReports={sosReports} onRespond={onRespond} />
          </LayerGroup>
        </LayersControl.Overlay>
        <LayersControl.Overlay checked name="Safe Zones">
          <LayerGroup>
            <ZoneMarkers safeZones={safeZones} />
          </LayerGroup>
        </LayersControl.Overlay>
        <LayersControl.Overlay checked name="Alerts">
          <LayerGroup>
            <AlertMarkers alerts={alerts} />
          </LayerGroup>
        </LayersControl.Overlay>
      </LayersControl>
      <FlyToSelectedSos sosReports={sosReports} selectedSosId={selectedSosId} />
    </MapContainer>
  );
}
