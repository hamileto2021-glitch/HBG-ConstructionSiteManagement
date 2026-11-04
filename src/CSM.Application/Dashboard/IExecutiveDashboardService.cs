using System;
using System.Threading;
using System.Threading.Tasks;
using CSM.Application.Dashboard.Dtos;

namespace CSM.Application.Dashboard;

public interface IExecutiveDashboardService
{
    Task<ExecutiveDashboardResponse> GetAsync(
        Guid companyId,
        Guid userId,
        CancellationToken cancellationToken = default);
}