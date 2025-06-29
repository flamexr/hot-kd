let currentData = {
    kills: 0,
    deaths: 0,
    kd_ratio: 0.00
};


const container = document.getElementById('kd-container');
const kdRatioElement = document.getElementById('kd-ratio');
const killsElement = document.getElementById('kills');
const deathsElement = document.getElementById('deaths');
const logoElement = document.getElementById('logo');


function animateValue(element, start, end, duration = 500) {
    const startTime = performance.now();
    const startValue = parseFloat(start) || 0;
    const endValue = parseFloat(end) || 0;
    const difference = endValue - startValue;

    function updateValue(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        

        const easedProgress = 1 - Math.pow(1 - progress, 3);
        
        const currentValue = startValue + (difference * easedProgress);
        
        if (element === kdRatioElement) {
            element.textContent = currentValue.toFixed(2);
        } else {
            element.textContent = Math.round(currentValue);
        }
        
        if (progress < 1) {
            requestAnimationFrame(updateValue);
        }
    }
    
    requestAnimationFrame(updateValue);
}

function addPulseAnimation(element) {
    element.classList.add('updated');
    setTimeout(() => {
        element.classList.remove('updated');
    }, 600);
}

function updateHighKDEffect(kdRatio) {
    if (kdRatio >= 2.0) {
        container.classList.add('high-kd');
    } else {
        container.classList.remove('high-kd');
    }
}


function updateData(newData) {
    const oldData = { ...currentData };
    

    if (oldData.kd_ratio !== newData.kd_ratio) {
        animateValue(kdRatioElement, oldData.kd_ratio, newData.kd_ratio);
        addPulseAnimation(kdRatioElement.parentElement);
    }
    

    if (oldData.kills !== newData.kills) {
        animateValue(killsElement, oldData.kills, newData.kills);
        addPulseAnimation(killsElement.parentElement);
    }
    

    if (oldData.deaths !== newData.deaths) {
        animateValue(deathsElement, oldData.deaths, newData.deaths);
        addPulseAnimation(deathsElement.parentElement);
    }
    

    updateHighKDEffect(newData.kd_ratio);
    
    currentData = { ...newData };
}


function toggleUI(show) {
    if (show) {
        container.classList.remove('hidden');
    } else {
        container.classList.add('hidden');
    }
}


window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'toggle':
            toggleUI(data.show);
            break;
            
        case 'updateData':
            updateData(data.data);
            break;
            
        case 'setLogo':
            if (data.logoUrl) {
                logoElement.src = data.logoUrl;
                logoElement.style.display = 'block';
            } else {
                logoElement.style.display = 'none';
            }
            break;
    }
});


logoElement.addEventListener('error', function() {
    this.style.display = 'none';
});


logoElement.addEventListener('load', function() {
    this.style.display = 'block';
});


document.addEventListener('keydown', function(event) {

    if (event.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({})
        });
    }
});


document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});


document.addEventListener('selectstart', function(event) {
    event.preventDefault();
});


document.addEventListener('dragstart', function(event) {
    event.preventDefault();
});


document.addEventListener('DOMContentLoaded', function() {

    if (!logoElement.src || logoElement.src.includes('logo.png')) {
        logoElement.style.display = 'none';
    }
    

    updateData(currentData);
});


function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}


function updateDataWithFormatting(newData) {
    const formattedData = {
        ...newData,
        kills: formatNumber(newData.kills),
        deaths: formatNumber(newData.deaths)
    };
    
    updateData(formattedData);
}


function GetParentResourceName() {
    return window.location.hostname;
}
