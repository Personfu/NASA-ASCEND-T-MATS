function fused = sensor_fusion_attitude(arduino, dt)
%SENSOR_FUSION_ATTITUDE  Madgwick-style 9-DOF attitude estimator.
%
%   fused = SENSOR_FUSION_ATTITUDE(arduino, dt) implements the Madgwick
%   gradient-descent quaternion filter using ICM-20948 gyro/accel and
%   LIS3MDL magnetometer telemetry from the Arduino science stack. Step
%   size dt is the average sample period (s).
%
%   Output: timetable with q0 q1 q2 q3 (quaternion), roll deg,
%   pitch deg, yaw deg, and total_g.
%
%   Reference: S. Madgwick, "An efficient orientation filter for inertial
%   and inertial/magnetic sensor arrays," 2010.

if nargin < 2, dt = 0.05; end           % 20 Hz nominal
beta = 0.041;                           % filter gain (rule of thumb)

T = arduino;
need = {'gyro_x','gyro_y','gyro_z','acc_x','acc_y','acc_z','mag_x','mag_y','mag_z'};
for k = 1:numel(need)
    if ~ismember(need{k}, T.Properties.VariableNames)
        warning('Missing field %s, skipping fusion.', need{k});
        fused = []; return;
    end
end

n = height(T);
q = zeros(n,4); q(1,:) = [1 0 0 0];
for i = 2:n
    gx = deg2rad(T.gyro_x(i)); gy = deg2rad(T.gyro_y(i)); gz = deg2rad(T.gyro_z(i));
    ax = T.acc_x(i);  ay = T.acc_y(i);  az = T.acc_z(i);
    mx = T.mag_x(i);  my = T.mag_y(i);  mz = T.mag_z(i);

    qi = q(i-1,:);
    if norm([ax ay az])>0 && norm([mx my mz])>0
        a = [ax ay az]/norm([ax ay az]);
        m = [mx my mz]/norm([mx my mz]);
        % Reference field
        h = quat_rot(qi, m);
        bx = hypot(h(1),h(2)); bz = h(3);
        % Gradient of objective function
        F = [2*(qi(2)*qi(4)-qi(1)*qi(3)) - a(1);
             2*(qi(1)*qi(2)+qi(3)*qi(4)) - a(2);
             2*(0.5-qi(2)^2-qi(3)^2)     - a(3);
             2*bx*(0.5-qi(3)^2-qi(4)^2) + 2*bz*(qi(2)*qi(4)-qi(1)*qi(3)) - m(1);
             2*bx*(qi(2)*qi(3)-qi(1)*qi(4)) + 2*bz*(qi(1)*qi(2)+qi(3)*qi(4)) - m(2);
             2*bx*(qi(1)*qi(3)+qi(2)*qi(4)) + 2*bz*(0.5-qi(2)^2-qi(3)^2)     - m(3)];
        J = madg_jacobian(qi, bx, bz);
        grad = (J.'*F).';
        if norm(grad)>0, grad = grad/norm(grad); end
    else
        grad = [0 0 0 0];
    end
    qDot = 0.5*quat_mul(qi,[0 gx gy gz]) - beta*grad;
    qi = qi + qDot*dt;
    q(i,:) = qi/norm(qi);
end

[roll, pitch, yaw] = arrayfun(@(k) quat_to_euler(q(k,:)), (1:n).');
fused = T;
fused.q0 = q(:,1); fused.q1 = q(:,2); fused.q2 = q(:,3); fused.q3 = q(:,4);
fused.roll_deg = rad2deg(roll);
fused.pitch_deg = rad2deg(pitch);
fused.yaw_deg = rad2deg(yaw);
end

function r = quat_rot(q, v)
qv = [0 v];
r = quat_mul(quat_mul(q,qv), quat_conj(q));
r = r(2:4);
end
function c = quat_mul(a,b)
c = [a(1)*b(1)-a(2)*b(2)-a(3)*b(3)-a(4)*b(4), ...
     a(1)*b(2)+a(2)*b(1)+a(3)*b(4)-a(4)*b(3), ...
     a(1)*b(3)-a(2)*b(4)+a(3)*b(1)+a(4)*b(2), ...
     a(1)*b(4)+a(2)*b(3)-a(3)*b(2)+a(4)*b(1)];
end
function c = quat_conj(q), c = [q(1) -q(2) -q(3) -q(4)]; end
function [r,p,y] = quat_to_euler(q)
r = atan2(2*(q(1)*q(2)+q(3)*q(4)), 1-2*(q(2)^2+q(3)^2));
p = asin( 2*(q(1)*q(3)-q(4)*q(2)));
y = atan2(2*(q(1)*q(4)+q(2)*q(3)), 1-2*(q(3)^2+q(4)^2));
end
function J = madg_jacobian(q, bx, bz)
J = [-2*q(3),  2*q(4), -2*q(1),  2*q(2);
      2*q(2),  2*q(1),  2*q(4),  2*q(3);
           0, -4*q(2), -4*q(3),       0;
   -2*bz*q(3), 2*bz*q(4), -4*bx*q(3)-2*bz*q(1), -4*bx*q(4)+2*bz*q(2);
   -2*bx*q(4)+2*bz*q(2), 2*bx*q(3)+2*bz*q(1), 2*bx*q(2)+2*bz*q(4), -2*bx*q(1)+2*bz*q(3);
    2*bx*q(3),  2*bx*q(4)-4*bz*q(2), 2*bx*q(1)-4*bz*q(3),  2*bx*q(2)];
end
