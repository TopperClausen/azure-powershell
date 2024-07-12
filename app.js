const openssl = require('openssl-wrapper');
const fs = require('fs');

require('dotenv').config();

openssl.exec('genrsa', {des3: true, passout: 'pass:' + process.env.password, '2048': false}, function(err, buffer) {
    fs.writeFileSync('private.pem', buffer);
    console.log(buffer.toString()); 
});