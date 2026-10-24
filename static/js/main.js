/**
 * Blood Bank Management System (BBMS) - Client Utilities
 */

// Export HTML Table to CSV File
function exportTableToCSV(tableId, filename = 'export.csv') {
  const table = document.getElementById(tableId);
  if (!table) {
    alert("Table not found for export!");
    return;
  }

  const rows = table.querySelectorAll('tr');
  const csvContent = [];

  rows.forEach(row => {
    // Skip rows marked with no-export class
    if (row.classList.contains('no-export')) return;

    const rowData = [];
    const cells = row.querySelectorAll('th, td');

    cells.forEach((cell, index) => {
      // Skip actions column (usually the last column)
      if (index === cells.length - 1 && cell.textContent.trim().toLowerCase().includes('action')) {
        return;
      }
      if (cell.querySelector('.btn') || cell.querySelector('.btn-group')) {
        return;
      }

      let text = cell.innerText.replace(/(\r\n|\n|\r)/gm, ' ').replace(/\s+/g, ' ').trim();
      // Escape quotes
      text = text.replace(/"/g, '""');
      rowData.push(`"${text}"`);
    });

    if (rowData.length > 0) {
      csvContent.push(rowData.join(','));
    }
  });

  const blob = new Blob([csvContent.join('\n')], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

// Client-side instant table search filter
function filterTable(inputId, tableId) {
  const input = document.getElementById(inputId);
  const filter = input.value.toLowerCase();
  const table = document.getElementById(tableId);
  if (!table) return;

  const rows = table.querySelectorAll('tbody tr');
  rows.forEach(row => {
    const text = row.textContent.toLowerCase();
    row.style.display = text.includes(filter) ? '' : 'none';
  });
}

// Filter table by specific column index
function filterTableByColumn(selectId, tableId, columnIndex) {
  const select = document.getElementById(selectId);
  const filter = select.value.toLowerCase().trim();
  const table = document.getElementById(tableId);
  if (!table) return;

  const rows = table.querySelectorAll('tbody tr');
  rows.forEach(row => {
    if (!filter) {
      row.style.display = '';
      return;
    }
    const cells = row.querySelectorAll('td');
    if (cells.length > columnIndex) {
      const cellText = cells[columnIndex].textContent.toLowerCase().trim();
      row.style.display = cellText.includes(filter) ? '' : 'none';
    }
  });
}

// Auto-dismiss alerts after 6 seconds
document.addEventListener('DOMContentLoaded', () => {
  const alerts = document.querySelectorAll('.alert-dismissible');
  alerts.forEach(alertEl => {
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alertEl);
      if (bsAlert) {
        bsAlert.close();
      }
    }, 6000);
  });
});
