/**
 * Blood Bank Management System (BBMS) - Application Modules Client API
 */

// =============================================================================
// DONOR MODULE
// =============================================================================

async function handleAddDonor(event) {
  event.preventDefault();
  const form = event.target;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch('/api/donors', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Donor added successfully!', 'success');
      closeModal('modal-add-donor');
      form.reset();
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to add donor', 'error');
    }
  } catch (err) {
    showToast('Network error occurred while saving donor', 'error');
  }
}

async function openEditDonorModal(donorId) {
  try {
    const res = await fetch(`/api/donors/${donorId}`);
    const donor = await res.json();
    if (!res.ok) {
      showToast(donor.error || 'Could not load donor details', 'error');
      return;
    }

    document.getElementById('edit-donor-id').value = donor.donor_id;
    document.getElementById('edit-donor-name').value = donor.name;
    document.getElementById('edit-donor-age').value = donor.age;
    document.getElementById('edit-donor-gender').value = donor.gender;
    document.getElementById('edit-donor-group').value = donor.blood_group_id;
    document.getElementById('edit-donor-phone').value = donor.phone;
    document.getElementById('edit-donor-email').value = donor.email || '';
    document.getElementById('edit-donor-address').value = donor.address;
    document.getElementById('edit-donor-clearance').value = donor.medical_clearance ? "1" : "0";

    openModal('modal-edit-donor');
  } catch (err) {
    showToast('Error fetching donor information', 'error');
  }
}

async function handleUpdateDonor(event) {
  event.preventDefault();
  const form = event.target;
  const donorId = document.getElementById('edit-donor-id').value;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch(`/api/donors/${donorId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Donor updated successfully!', 'success');
      closeModal('modal-edit-donor');
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to update donor', 'error');
    }
  } catch (err) {
    showToast('Network error while updating donor', 'error');
  }
}

async function deleteDonor(donorId, donorName) {
  if (!confirm(`Are you sure you want to delete donor "${donorName}"? This action cannot be undone.`)) {
    return;
  }

  try {
    const res = await fetch(`/api/donors/${donorId}`, { method: 'DELETE' });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Donor deleted successfully', 'success');
      setTimeout(() => window.location.reload(), 700);
    } else {
      showToast(result.error || 'Unable to delete donor. They may have linked donation records.', 'error');
    }
  } catch (err) {
    showToast('Network error while deleting donor', 'error');
  }
}

// =============================================================================
// BLOOD DONATION MODULE
// =============================================================================

async function handleRecordDonation(event) {
  event.preventDefault();
  const form = event.target;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch('/api/donations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Donation recorded and blood stock updated!', 'success');
      closeModal('modal-add-donation');
      form.reset();
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to record donation', 'error');
    }
  } catch (err) {
    showToast('Network error while saving donation record', 'error');
  }
}

// Auto-fill donor's blood group when selected in donation modal
function onDonorSelected(selectElement) {
  const selectedOption = selectElement.options[selectElement.selectedIndex];
  const bloodGroupId = selectedOption.getAttribute('data-group-id');
  const bloodGroupName = selectedOption.getAttribute('data-group-name');
  
  const groupSelect = document.getElementById('donation-blood-group');
  if (groupSelect && bloodGroupId) {
    groupSelect.value = bloodGroupId;
  }
}

// =============================================================================
// BLOOD REQUEST & APPROVAL MODULE
// =============================================================================

async function handleCreateRequest(event) {
  event.preventDefault();
  const form = event.target;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch('/api/requests', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Blood request created successfully!', 'success');
      closeModal('modal-add-request');
      form.reset();
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to submit blood request', 'error');
    }
  } catch (err) {
    showToast('Network error while submitting request', 'error');
  }
}

async function approveRequest(requestId, patientName, units, bloodGroup) {
  if (!confirm(`Confirm approval for Request #${requestId}?\n\nPatient: ${patientName}\nRequired: ${units} unit(s) of ${bloodGroup}\n\nThis will automatically verify stock and deduct ${units} unit(s).`)) {
    return;
  }

  try {
    const res = await fetch(`/api/requests/${requestId}/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Request approved and blood stock deducted!', 'success');
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Approval rejected: Insufficient stock available!', 'error');
    }
  } catch (err) {
    showToast('Network error processing request approval', 'error');
  }
}

async function rejectRequest(requestId, patientName) {
  const remarks = prompt(`Enter reason for rejecting request for patient "${patientName}":`, 'Transfusion requirements could not be fulfilled');
  if (remarks === null) return;

  try {
    const res = await fetch(`/api/requests/${requestId}/reject`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ remarks })
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Request rejected successfully', 'info');
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to reject request', 'error');
    }
  } catch (err) {
    showToast('Network error processing rejection', 'error');
  }
}

// =============================================================================
// HOSPITAL MODULE
// =============================================================================

async function handleAddHospital(event) {
  event.preventDefault();
  const form = event.target;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch('/api/hospitals', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Hospital added successfully!', 'success');
      closeModal('modal-add-hospital');
      form.reset();
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to save hospital', 'error');
    }
  } catch (err) {
    showToast('Network error while saving hospital', 'error');
  }
}

async function openEditHospitalModal(hospitalId) {
  try {
    const res = await fetch(`/api/hospitals/${hospitalId}`);
    const hospital = await res.json();
    if (!res.ok) {
      showToast(hospital.error || 'Could not load hospital details', 'error');
      return;
    }

    document.getElementById('edit-hospital-id').value = hospital.hospital_id;
    document.getElementById('edit-hospital-name').value = hospital.hospital_name;
    document.getElementById('edit-hospital-license').value = hospital.license_number;
    document.getElementById('edit-hospital-phone').value = hospital.contact_number;
    document.getElementById('edit-hospital-email').value = hospital.email;
    document.getElementById('edit-hospital-emergency').value = hospital.emergency_contact || '';
    document.getElementById('edit-hospital-address').value = hospital.address;

    openModal('modal-edit-hospital');
  } catch (err) {
    showToast('Error loading hospital details', 'error');
  }
}

async function handleUpdateHospital(event) {
  event.preventDefault();
  const form = event.target;
  const hospitalId = document.getElementById('edit-hospital-id').value;
  const formData = new FormData(form);
  const data = Object.fromEntries(formData.entries());

  try {
    const res = await fetch(`/api/hospitals/${hospitalId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Hospital details updated!', 'success');
      closeModal('modal-edit-hospital');
      setTimeout(() => window.location.reload(), 800);
    } else {
      showToast(result.error || 'Failed to update hospital', 'error');
    }
  } catch (err) {
    showToast('Network error while updating hospital', 'error');
  }
}

async function deleteHospital(hospitalId, hospitalName) {
  if (!confirm(`Are you sure you want to delete "${hospitalName}"?`)) {
    return;
  }

  try {
    const res = await fetch(`/api/hospitals/${hospitalId}`, { method: 'DELETE' });
    const result = await res.json();
    if (res.ok) {
      showToast(result.message || 'Hospital deleted successfully', 'success');
      setTimeout(() => window.location.reload(), 700);
    } else {
      showToast(result.error || 'Cannot delete hospital with existing requests or patient records.', 'error');
    }
  } catch (err) {
    showToast('Network error while deleting hospital', 'error');
  }
}

// =============================================================================
// BLOOD COMPATIBILITY CALCULATOR (SEARCH PAGE)
// =============================================================================

const COMPATIBILITY_RULES = {
  'A+': {
    canDonateTo: ['A+', 'AB+'],
    canReceiveFrom: ['A+', 'A-', 'O+', 'O-'],
    universalStatus: 'Common'
  },
  'A-': {
    canDonateTo: ['A+', 'A-', 'AB+', 'AB-'],
    canReceiveFrom: ['A-', 'O-'],
    universalStatus: 'Universal Platelets Donor'
  },
  'B+': {
    canDonateTo: ['B+', 'AB+'],
    canReceiveFrom: ['B+', 'B-', 'O+', 'O-'],
    universalStatus: 'Common'
  },
  'B-': {
    canDonateTo: ['B+', 'B-', 'AB+', 'AB-'],
    canReceiveFrom: ['B-', 'O-'],
    universalStatus: 'Rare'
  },
  'AB+': {
    canDonateTo: ['AB+'],
    canReceiveFrom: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    universalStatus: 'Universal Recipient'
  },
  'AB-': {
    canDonateTo: ['AB+', 'AB-'],
    canReceiveFrom: ['AB-', 'A-', 'B-', 'O-'],
    universalStatus: 'Rarest Blood Group'
  },
  'O+': {
    canDonateTo: ['O+', 'A+', 'B+', 'AB+'],
    canReceiveFrom: ['O+', 'O-'],
    universalStatus: 'Most Requested'
  },
  'O-': {
    canDonateTo: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    canReceiveFrom: ['O-'],
    universalStatus: 'Universal Red Cell Donor'
  }
};

function checkCompatibility() {
  const groupSelect = document.getElementById('search-blood-group');
  const unitsInput = document.getElementById('search-units-needed');
  const resultsCard = document.getElementById('search-results-card');
  if (!groupSelect || !resultsCard) return;

  const group = groupSelect.value;
  const unitsNeeded = parseInt(unitsInput.value, 10) || 1;

  if (!group || !COMPATIBILITY_RULES[group]) {
    resultsCard.style.display = 'none';
    return;
  }

  const info = COMPATIBILITY_RULES[group];
  
  // Find current units available from stock cards or window.STOCK_DATA
  let availableUnits = 0;
  if (window.STOCK_DATA && window.STOCK_DATA[group] !== undefined) {
    availableUnits = window.STOCK_DATA[group];
  }

  document.getElementById('comp-group-title').innerText = group;
  document.getElementById('comp-badge-status').innerText = info.universalStatus;
  document.getElementById('comp-stock-avail').innerText = `${availableUnits} units available`;
  
  // Requirement Fulfillment assessment
  const fulfillElem = document.getElementById('comp-fulfillment');
  if (availableUnits >= unitsNeeded) {
    fulfillElem.className = 'badge badge-approved';
    fulfillElem.innerText = `Sufficient Stock Available (${availableUnits} >= ${unitsNeeded})`;
  } else {
    fulfillElem.className = 'badge badge-rejected';
    fulfillElem.innerText = `Insufficient Direct Stock! (${availableUnits} < ${unitsNeeded} needed)`;
  }

  // Compatible donors and recipients
  document.getElementById('comp-can-receive').innerText = info.canReceiveFrom.join(', ');
  document.getElementById('comp-can-donate').innerText = info.canDonateTo.join(', ');

  resultsCard.style.display = 'block';
}
